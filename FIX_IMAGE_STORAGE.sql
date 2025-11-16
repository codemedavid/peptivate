-- ============================================
-- COMPLETE FIX FOR IMAGE STORAGE ISSUES
-- ============================================
-- Run this in Supabase SQL Editor to fix all image storage problems
-- This script addresses: bucket creation, policies, database column, and RLS

-- ============================================
-- PART 1: ENSURE DATABASE COLUMN EXISTS
-- ============================================
DO $$ 
BEGIN
    -- Add image_url column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'products' 
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE products ADD COLUMN image_url TEXT;
        RAISE NOTICE '✅ Added image_url column to products table';
    ELSE
        RAISE NOTICE '✅ image_url column already exists';
    END IF;
    
    -- Ensure it's TEXT type (not VARCHAR with length limit)
    ALTER TABLE products ALTER COLUMN image_url TYPE TEXT;
    RAISE NOTICE '✅ image_url column is TEXT type (supports long URLs)';
END $$;

-- ============================================
-- PART 2: CREATE STORAGE BUCKET
-- ============================================
-- Create the menu-images bucket if it doesn't exist
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

-- ============================================
-- PART 3: CREATE STORAGE POLICIES
-- ============================================
-- Allow public read access (so images can be displayed)
DROP POLICY IF EXISTS "Public read access for menu images" ON storage.objects;
CREATE POLICY "Public read access for menu images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'menu-images');

-- Allow anyone to upload (for admin panel)
DROP POLICY IF EXISTS "Anyone can upload menu images" ON storage.objects;
CREATE POLICY "Anyone can upload menu images"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'menu-images');

-- Allow updates (for replacing images)
DROP POLICY IF EXISTS "Anyone can update menu images" ON storage.objects;
CREATE POLICY "Anyone can update menu images"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'menu-images')
WITH CHECK (bucket_id = 'menu-images');

-- Allow deletes (for removing images)
DROP POLICY IF EXISTS "Anyone can delete menu images" ON storage.objects;
CREATE POLICY "Anyone can delete menu images"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'menu-images');

-- ============================================
-- PART 4: FIX RLS POLICIES FOR PRODUCTS TABLE
-- ============================================
-- Check if RLS is enabled and create/update UPDATE policy
DO $$
BEGIN
    -- Check if RLS is enabled on products table
    IF EXISTS (
        SELECT 1 
        FROM pg_tables 
        WHERE tablename = 'products' 
        AND rowsecurity = true
    ) THEN
        -- RLS is enabled, create UPDATE policy if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_policies 
            WHERE tablename = 'products' 
            AND policyname = 'Allow product updates'
        ) THEN
            CREATE POLICY "Allow product updates" ON products
            FOR UPDATE
            USING (true)
            WITH CHECK (true);
            RAISE NOTICE '✅ Created UPDATE policy for products table';
        ELSE
            -- Policy exists, but let's make sure it's correct
            DROP POLICY IF EXISTS "Allow product updates" ON products;
            CREATE POLICY "Allow product updates" ON products
            FOR UPDATE
            USING (true)
            WITH CHECK (true);
            RAISE NOTICE '✅ Updated UPDATE policy for products table';
        END IF;
    ELSE
        RAISE NOTICE 'ℹ️ RLS is not enabled on products table - no policy needed';
    END IF;
END $$;

-- ============================================
-- PART 5: VERIFICATION
-- ============================================
-- Verify bucket was created
SELECT 
    '=== STORAGE BUCKET ===' as check_type,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    CASE 
        WHEN id IS NULL THEN '❌ FAILED - Bucket not created'
        WHEN public = false THEN '⚠️ WARNING - Bucket is private (should be public)'
        ELSE '✅ SUCCESS - Bucket exists and is public'
    END as status
FROM storage.buckets
WHERE id = 'menu-images';

-- Verify storage policies
SELECT 
    '=== STORAGE POLICIES ===' as check_type,
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Read policy'
        WHEN cmd = 'INSERT' THEN '✅ Upload policy'
        WHEN cmd = 'UPDATE' THEN '✅ Update policy'
        WHEN cmd = 'DELETE' THEN '✅ Delete policy'
        ELSE 'ℹ️ Other policy'
    END as status
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%')
ORDER BY cmd;

-- Verify database column
SELECT 
    '=== DATABASE COLUMN ===' as check_type,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IS NULL THEN '❌ FAILED - Column does not exist'
        WHEN data_type != 'text' THEN '⚠️ WARNING - Wrong type: ' || data_type
        ELSE '✅ SUCCESS - Column exists and is TEXT type'
    END as status
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- Verify RLS policy
SELECT 
    '=== RLS POLICY ===' as check_type,
    policyname,
    cmd as operation,
    CASE 
        WHEN policyname IS NULL THEN '⚠️ WARNING - No UPDATE policy found (RLS may block updates)'
        ELSE '✅ SUCCESS - UPDATE policy exists'
    END as status
FROM pg_policies
WHERE tablename = 'products' 
AND cmd = 'UPDATE';

-- ============================================
-- PART 6: SUMMARY
-- ============================================
SELECT 
    '=== FIX SUMMARY ===' as summary_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'menu-images' AND public = true)
            AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'image_url')
            AND EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND cmd = 'INSERT' AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%'))
        THEN '✅ ALL CHECKS PASSED - Image storage should work now!'
        ELSE '⚠️ SOME CHECKS FAILED - Review the verification results above'
    END as overall_status;

-- ============================================
-- DONE! 
-- ============================================
-- If you see "ALL CHECKS PASSED" above, image storage should work!
-- 
-- Next steps:
-- 1. Go to /admin in your app
-- 2. Edit a product
-- 3. Upload an image
-- 4. Check browser console (F12) for any errors
-- 5. Save the product
-- 6. Verify image appears in the database

