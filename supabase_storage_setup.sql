-- =============================================
-- Baby Tracker Flutter - Supabase Storage Setup
-- =============================================

-- =============================================
-- 1. CREATE STORAGE BUCKETS
-- =============================================

-- Create bucket for baby memories (photos, videos)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('memories', 'memories', true)
ON CONFLICT (id) DO NOTHING;

-- Create bucket for baby avatars
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- 2. STORAGE POLICIES FOR MEMORIES BUCKET
-- =============================================

-- Allow authenticated users to upload files to their own folder
CREATE POLICY "Users can upload memories for their babies" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'memories' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to view files in their own folder
CREATE POLICY "Users can view their own memories" ON storage.objects
FOR SELECT USING (
    bucket_id = 'memories' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to update files in their own folder
CREATE POLICY "Users can update their own memories" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'memories' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to delete files in their own folder
CREATE POLICY "Users can delete their own memories" ON storage.objects
FOR DELETE USING (
    bucket_id = 'memories' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- =============================================
-- 3. STORAGE POLICIES FOR AVATARS BUCKET
-- =============================================

-- Allow authenticated users to upload avatars to their own folder
CREATE POLICY "Users can upload avatars for their babies" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to view avatars in their own folder
CREATE POLICY "Users can view their own avatars" ON storage.objects
FOR SELECT USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to update avatars in their own folder
CREATE POLICY "Users can update their own avatars" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to delete avatars in their own folder
CREATE POLICY "Users can delete their own avatars" ON storage.objects
FOR DELETE USING (
    bucket_id = 'avatars' 
    AND auth.role() = 'authenticated'
    AND (auth.uid())::text = (storage.foldername(name))[1]
);

-- =============================================
-- 4. PUBLIC ACCESS POLICIES (if needed)
-- =============================================

-- If you want to allow public viewing of memories (be careful with this)
-- CREATE POLICY "Public can view memories" ON storage.objects
-- FOR SELECT USING (bucket_id = 'memories');

-- If you want to allow public viewing of avatars
-- CREATE POLICY "Public can view avatars" ON storage.objects
-- FOR SELECT USING (bucket_id = 'avatars');

-- =============================================
-- STORAGE SETUP COMPLETE
-- =============================================

-- File upload structure will be:
-- memories/[user_id]/[baby_id]/[memory_id]_[timestamp].[extension]
-- avatars/[user_id]/[baby_id]/avatar.[extension]
