-- Create Supabase Storage Buckets
INSERT INTO storage.buckets (id, name, public) VALUES
('profile-images', 'profile-images', true),
('gallery', 'gallery', true),
('chat-media', 'chat-media', false),
('community-media', 'community-media', false)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for profile-images
CREATE POLICY "Public Access for profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');
CREATE POLICY "Authenticated users can upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'profile-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update their own profile images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete their own profile images" ON storage.objects
    FOR DELETE USING (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- RLS Policies for gallery
CREATE POLICY "Public Access for gallery" ON storage.objects
    FOR SELECT USING (bucket_id = 'gallery');
CREATE POLICY "Authenticated users can upload gallery images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'gallery' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update their own gallery images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'gallery' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete their own gallery images" ON storage.objects
    FOR DELETE USING (bucket_id = 'gallery' AND auth.uid()::text = (storage.foldername(name))[1]);

-- RLS Policies for chat-media (Authenticated Only)
CREATE POLICY "Authenticated users can read chat-media" ON storage.objects
    FOR SELECT USING (bucket_id = 'chat-media' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can upload chat-media" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'chat-media' AND auth.role() = 'authenticated');

-- RLS Policies for community-media (Authenticated Only)
CREATE POLICY "Authenticated users can read community-media" ON storage.objects
    FOR SELECT USING (bucket_id = 'community-media' AND auth.role() = 'authenticated');
-- We omit the broad INSERT policy here because there is a more specific
-- policy elsewhere (`Members upload community media`) which properly gates upload rights.
