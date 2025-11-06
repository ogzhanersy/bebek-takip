import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// JWT creation for FCM V1 API
async function createJWT(serviceAccountKey: string): Promise<string> {
  try {
    console.log('Creating JWT with service account key...')
    const serviceAccount = JSON.parse(serviceAccountKey)
    
    if (!serviceAccount.private_key) {
      throw new Error('private_key not found in service account')
    }
    
    console.log('Service account parsed successfully')
    
    const header = {
      alg: 'RS256',
      typ: 'JWT',
    }

    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/cloud-platform',
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now,
    }

    const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    
    const signatureInput = `${encodedHeader}.${encodedPayload}`
    
    // Convert PEM private key to ArrayBuffer
    const privateKeyPem = serviceAccount.private_key
      .replace(/-----BEGIN PRIVATE KEY-----/, '')
      .replace(/-----END PRIVATE KEY-----/, '')
      .replace(/\s/g, '')
    
    const privateKeyBuffer = Uint8Array.from(atob(privateKeyPem), c => c.charCodeAt(0))
    
    // Import the private key
    const privateKey = await crypto.subtle.importKey(
      'pkcs8',
      privateKeyBuffer,
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )

    // Sign the JWT
    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      privateKey,
      new TextEncoder().encode(signatureInput)
    )

    const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')

    console.log('JWT created successfully')
    return `${signatureInput}.${encodedSignature}`
  } catch (error) {
    console.error('JWT Creation Error:', error)
    throw new Error(`Failed to create JWT: ${error.message}`)
  }
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the request body
    const { type, userId, babyId, title, body, data } = await req.json()

    // Validate required fields
    if (!type || !userId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: type, userId' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get user's FCM token from fcm_tokens table
    const { data: tokenData, error: tokenError } = await supabaseClient
      .from('fcm_tokens')
      .select('token')
      .eq('user_id', userId)
      .order('updated_at', { ascending: false })
      .limit(1)
      .single()
    
    if (tokenError || !tokenData) {
      console.error('FCM token fetch error:', tokenError)
      return new Response(
        JSON.stringify({ error: 'FCM token not found for user', details: tokenError?.message }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const fcmToken = tokenData.token
    
    if (!fcmToken) {
      return new Response(
        JSON.stringify({ error: 'FCM token not found for user' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Prepare notification payload
    const notificationPayload = {
      to: fcmToken,
      notification: {
        title: title || getDefaultTitle(type),
        body: body || getDefaultBody(type),
        icon: 'ic_launcher',
        sound: 'default',
      },
      data: {
        type: type,
        userId: userId,
        babyId: babyId || '',
        ...data,
      },
      priority: 'high',
    }

    // Send notification via FCM using Service Account
    const serviceAccountKey = Deno.env.get('FCM_SERVICE_ACCOUNT_KEY')
    console.log('Service Account Key exists:', !!serviceAccountKey)
    console.log('Service Account Key length:', serviceAccountKey?.length || 0)
    
    if (!serviceAccountKey) {
      console.error('FCM Service Account Key not found in environment variables')
      return new Response(
        JSON.stringify({ error: 'FCM Service Account Key not configured' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create JWT token for authentication
    const jwt = await createJWT(serviceAccountKey)
    
    // Exchange JWT for Access Token
    console.log('Exchanging JWT for Access Token...')
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    })
    
    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('Token exchange error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to get access token', details: errorText }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }
    
    const accessTokenData = await tokenResponse.json()
    const accessToken = accessTokenData.access_token
    console.log('Access Token obtained successfully')
    
    // Send notification via FCM V1 API
    console.log('Sending to FCM with Access Token...')
    console.log('FCM Project ID:', Deno.env.get('FCM_PROJECT_ID'))
    console.log('FCM Token:', fcmToken)
    
    const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${Deno.env.get('FCM_PROJECT_ID')}/messages:send`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: title || getDefaultTitle(type),
            body: body || getDefaultBody(type),
          },
          data: {
            type: type,
            userId: userId,
            babyId: babyId || '',
            ...data,
          },
        },
      }),
    })

    if (!fcmResponse.ok) {
      const errorText = await fcmResponse.text()
      console.error('FCM Error:', errorText)
      return new Response(
        JSON.stringify({ error: 'Failed to send notification', details: errorText }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const fcmResult = await fcmResponse.json()
    console.log('FCM Success:', fcmResult)

    // Log notification in database
    const { error: logError } = await supabaseClient
      .from('notification_logs')
      .insert({
        user_id: userId,
        baby_id: babyId,
        type: type,
        title: notificationPayload.notification.title,
        body: notificationPayload.notification.body,
        fcm_response: fcmResult,
        sent_at: new Date().toISOString(),
      })

    if (logError) {
      console.error('Log Error:', logError)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: fcmResult.message_id,
        type: type 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Function Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

// Helper functions for default messages
function getDefaultTitle(type: string): string {
  const titles = {
    'feeding_reminder': '🍼 Beslenme Zamanı',
    'sleep_reminder': '😴 Uyku Zamanı',
    'diaper_reminder': '👶 Alt Değişimi',
    'development_reminder': '📏 Gelişim Takibi',
    'daily_summary': '📊 Günlük Özet',
    'test': '🧪 Test Bildirimi',
  }
  return titles[type] || 'Bebek Takip'
}

function getDefaultBody(type: string): string {
  const bodies = {
    'feeding_reminder': 'Bebeğinizin beslenme zamanı geldi!',
    'sleep_reminder': 'Bebeğinizin uyku zamanı geldi!',
    'diaper_reminder': 'Bebeğinizin alt değişimi zamanı geldi!',
    'development_reminder': 'Bebeğinizin gelişim ölçümü zamanı geldi!',
    'daily_summary': 'Bugünkü aktivitelerinizi kontrol edin.',
    'test': 'Firebase bildirim sistemi çalışıyor!',
  }
  return bodies[type] || 'Yeni bildirim'
}
