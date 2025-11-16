-- ============================================
-- DIAGNOSTIC SCRIPT FOR IMAGE UPLOAD ISSUES
-- ============================================
-- Run this in Supabase SQL Editor to diagnose image upload problems
-- This will check all common issues and provide a report

-- ============================================
-- PART 1: CHECK DATABASE COLUMN
-- ============================================
SELECT 
    '=== DATABASE COLUMN CHECK ===' as section;

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IS NULL THEN '❌ MISSING - Column does not exist!'
        WHEN data_type != 'text' THEN '⚠️ WARNING - Column exists but wrong type: ' || data_type
        ELSE '✅ OK - Column exists and is TEXT type'
    END as status
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- ============================================
-- PART 2: CHECK RLS STATUS
-- ============================================
SELECT 
    '=== ROW LEVEL SECURITY CHECK ===' as section;

SELECT 
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN '⚠️ RLS IS ENABLED - Check policies below'
        ELSE '✅ RLS is disabled - Updates should work'
    END as status
FROM pg_tables
WHERE tablename = 'products';

-- ============================================
-- PART 3: CHECK RLS POLICIES
-- ============================================
SELECT 
    '=== RLS POLICIES CHECK ===' as section;

SELECT 
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'UPDATE' THEN '✅ UPDATE policy exists'
        ELSE 'ℹ️ Policy for: ' || cmd
    END as status,
    qual as using_clause,
    with_check as with_check_clause
FROM pg_policies
WHERE tablename = 'products'
ORDER BY cmd;

-- If no UPDATE policy exists, you'll see no rows or only SELECT policies
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ NO POLICIES FOUND - RLS may be blocking updates!'
        WHEN COUNT(*) FILTER (WHERE cmd = 'UPDATE') = 0 THEN '❌ NO UPDATE POLICY - Updates will fail!'
        ELSE '✅ UPDATE policy exists'
    END as update_policy_status
FROM pg_policies
WHERE tablename = 'products' AND cmd = 'UPDATE';

-- ============================================
-- PART 4: CHECK STORAGE BUCKET
-- ============================================
SELECT 
    '=== STORAGE BUCKET CHECK ===' as section;

SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    CASE 
        WHEN id IS NULL THEN '❌ MISSING - Bucket does not exist!'
        WHEN public = false THEN '⚠️ WARNING - Bucket exists but is PRIVATE (should be public)'
        ELSE '✅ OK - Bucket exists and is public'
    END as status
FROM storage.buckets
WHERE id = 'menu-images';

-- ============================================
-- PART 5: CHECK STORAGE POLICIES
-- ============================================
SELECT 
    '=== STORAGE POLICIES CHECK ===' as section;

SELECT 
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN '✅ Public read policy'
        WHEN cmd = 'INSERT' THEN '✅ Upload policy'
        WHEN cmd = 'UPDATE' THEN '✅ Update policy'
        WHEN cmd = 'DELETE' THEN '✅ Delete policy'
        ELSE 'ℹ️ Policy for: ' || cmd
    END as status
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%menu-images%' OR policyname LIKE '%menu%'
ORDER BY cmd;

-- Count policies by operation
SELECT 
    cmd as operation,
    COUNT(*) as policy_count,
    CASE 
        WHEN cmd = 'SELECT' AND COUNT(*) > 0 THEN '✅ Read policy exists'
        WHEN cmd = 'INSERT' AND COUNT(*) > 0 THEN '✅ Upload policy exists'
        WHEN cmd = 'UPDATE' AND COUNT(*) > 0 THEN '✅ Update policy exists'
        WHEN cmd = 'DELETE' AND COUNT(*) > 0 THEN '✅ Delete policy exists'
        ELSE '❌ Missing policy for ' || cmd
    END as status
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%')
GROUP BY cmd
ORDER BY cmd;

-- ============================================
-- PART 6: CHECK CURRENT PRODUCTS
-- ============================================
SELECT 
    '=== CURRENT PRODUCTS STATUS ===' as section;

SELECT 
    id,
    name,
    CASE 
        WHEN image_url IS NULL THEN '❌ No image'
        WHEN image_url = '' THEN '❌ Empty URL'
        WHEN image_url LIKE 'https://%' THEN '✅ Has image URL'
        ELSE '⚠️ Has value: ' || LEFT(image_url, 30)
    END as image_status,
    LEFT(image_url, 50) as image_url_preview,
    updated_at
FROM products
ORDER BY updated_at DESC
LIMIT 10;

-- Summary
SELECT 
    '=== SUMMARY ===' as section;

SELECT 
    COUNT(*) as total_products,
    COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as products_with_images,
    COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as products_without_images,
    ROUND(100.0 * COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') / COUNT(*), 1) as percentage_with_images
FROM products;

-- ============================================
-- PART 7: RECOMMENDATIONS
-- ============================================
SELECT 
    '=== RECOMMENDATIONS ===' as section;

-- Generate recommendations based on findings
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'image_url'
        ) THEN '❌ ACTION REQUIRED: Add image_url column - Run: ALTER TABLE products ADD COLUMN image_url TEXT;'
        ELSE '✅ Column exists'
    END as recommendation_1
UNION ALL
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE tablename = 'products' AND rowsecurity = true
        ) AND NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'products' AND cmd = 'UPDATE'
        ) THEN '❌ ACTION REQUIRED: Create UPDATE policy - Run: CREATE POLICY "Allow product updates" ON products FOR UPDATE USING (true) WITH CHECK (true);'
        ELSE '✅ RLS/Policy OK'
    END as recommendation_2
UNION ALL
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM storage.buckets WHERE id = 'menu-images'
        ) THEN '❌ ACTION REQUIRED: Create storage bucket - Run CREATE_STORAGE_BUCKET.sql'
        WHEN EXISTS (
            SELECT 1 FROM storage.buckets WHERE id = 'menu-images' AND public = false
        ) THEN '⚠️ WARNING: Bucket exists but is private - Should be public'
        ELSE '✅ Storage bucket OK'
    END as recommendation_3
UNION ALL
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'storage' 
            AND tablename = 'objects' 
            AND cmd = 'INSERT'
            AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%')
        ) THEN '❌ ACTION REQUIRED: Create storage upload policy - Run CREATE_STORAGE_BUCKET.sql'
        ELSE '✅ Storage policies OK'
    END as recommendation_4;


