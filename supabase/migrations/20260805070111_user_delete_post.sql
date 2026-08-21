CREATE POLICY "Users can delete their own posts" ON public.community_posts
FOR DELETE USING (auth.uid() = author_id);
