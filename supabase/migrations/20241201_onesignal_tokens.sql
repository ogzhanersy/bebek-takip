-- OneSignal tokens table
CREATE TABLE IF NOT EXISTS onesignal_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  player_id TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, player_id)
);

-- Enable RLS
ALTER TABLE onesignal_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own OneSignal tokens" ON onesignal_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own OneSignal tokens" ON onesignal_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own OneSignal tokens" ON onesignal_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own OneSignal tokens" ON onesignal_tokens
  FOR DELETE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_onesignal_tokens_user_id ON onesignal_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_onesignal_tokens_player_id ON onesignal_tokens(player_id);
