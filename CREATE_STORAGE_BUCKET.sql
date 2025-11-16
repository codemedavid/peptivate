-- ============================================
-- CREATE STORAGE BUCKET FOR PRODUCT IMAGES
-- ============================================
-- Run this in Supabase SQL Editor to create the bucket and policies

-- Step 1: Create the storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'menu-images',
  'menu-images',
  true,  -- Public bucket (important!)
  5242880,  -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO UPDATE
SET 
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- Step 2: Allow public read access (so images can be displayed)
DROP POLICY IF EXISTS "Public read access for menu images" ON storage.objects;
CREATE POLICY "Public read access for menu images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'menu-images');

-- Step 3: Allow anyone to upload (for admin panel - adjust if you want auth-only)
DROP POLICY IF EXISTS "Anyone can upload menu images" ON storage.objects;
CREATE POLICY "Anyone can upload menu images"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'menu-images');

-- Step 4: Allow updates (for replacing images)
DROP POLICY IF EXISTS "Anyone can update menu images" ON storage.objects;
CREATE POLICY "Anyone can update menu images"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'menu-images')
WITH CHECK (bucket_id = 'menu-images');

-- Step 5: Allow deletes (for removing images)
DROP POLICY IF EXISTS "Anyone can delete menu images" ON storage.objects;
CREATE POLICY "Anyone can delete menu images"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'menu-images');

-- Step 6: Verify bucket was created
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE id = 'menu-images';

-- If you see the bucket above, it's created successfully! ✅

