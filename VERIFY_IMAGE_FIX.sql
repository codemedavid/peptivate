-- ============================================
-- VERIFY IMAGE STORAGE FIX - Run After Code Changes
-- ============================================
-- This script verifies that the image storage fix is working correctly

-- Step 1: Verify Database Column
SELECT 
    '=== DATABASE COLUMN CHECK ===' as check_section,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name IS NULL THEN '❌ FAILED'
        WHEN data_type = 'text' THEN '✅ PASS'
        ELSE '⚠️ WARNING - Wrong type'
    END as status
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- Step 2: Verify Storage Bucket
SELECT 
    '=== STORAGE BUCKET CHECK ===' as check_section,
    id,
    name,
    public,
    CASE 
        WHEN id IS NULL THEN '❌ FAILED - Bucket missing'
        WHEN public = false THEN '⚠️ WARNING - Bucket is private'
        ELSE '✅ PASS'
    END as status
FROM storage.buckets
WHERE id = 'menu-images';

-- Step 3: Verify Storage Policies
SELECT 
    '=== STORAGE POLICIES CHECK ===' as check_section,
    COUNT(*) FILTER (WHERE cmd = 'SELECT') as read_policies,
    COUNT(*) FILTER (WHERE cmd = 'INSERT') as upload_policies,
    COUNT(*) FILTER (WHERE cmd = 'UPDATE') as update_policies,
    COUNT(*) FILTER (WHERE cmd = 'DELETE') as delete_policies,
    CASE 
        WHEN COUNT(*) FILTER (WHERE cmd = 'INSERT') = 0 THEN '❌ FAILED - No upload policy'
        WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT') = 0 THEN '⚠️ WARNING - No read policy'
        ELSE '✅ PASS'
    END as status
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%');

-- Step 4: Verify RLS Policy (if RLS is enabled)
SELECT 
    '=== RLS POLICY CHECK ===' as check_section,
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'products' AND cmd = 'UPDATE') as update_policy_count,
    CASE 
        WHEN rowsecurity = true AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'products' AND cmd = 'UPDATE') = 0 
            THEN '❌ FAILED - RLS enabled but no UPDATE policy'
        WHEN rowsecurity = false THEN '✅ PASS - RLS disabled'
        WHEN rowsecurity = true AND (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'products' AND cmd = 'UPDATE') > 0 
            THEN '✅ PASS - RLS enabled with UPDATE policy'
        ELSE '⚠️ WARNING'
    END as status
FROM pg_tables
WHERE tablename = 'products';

-- Step 5: Test Update (Safe - uses a test value)
-- This will show if updates work, but won't modify real data
SELECT 
    '=== UPDATE TEST ===' as check_section,
    'Run this manually with a real product ID:' as instruction,
    'UPDATE products SET image_url = ''https://test.com/image.jpg'' WHERE id = ''YOUR_PRODUCT_ID'' RETURNING id, name, image_url;' as test_query;

-- Step 6: Check Current Products with Images
SELECT 
    '=== CURRENT PRODUCTS STATUS ===' as check_section,
    COUNT(*) as total_products,
    COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as products_with_images,
    COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as products_without_images,
    ROUND(100.0 * COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') / NULLIF(COUNT(*), 0), 1) as percentage_with_images
FROM products;

-- Step 7: Show Recent Products (to verify manually)
SELECT 
    '=== RECENT PRODUCTS (Last 5) ===' as check_section,
    id,
    name,
    CASE 
        WHEN image_url IS NULL THEN '❌ No image'
        WHEN image_url = '' THEN '❌ Empty URL'
        ELSE '✅ Has image: ' || LEFT(image_url, 50) || '...'
    END as image_status,
    updated_at
FROM products
ORDER BY updated_at DESC
LIMIT 5;

-- ============================================
-- SUMMARY
-- ============================================
SELECT 
    '=== OVERALL STATUS ===' as summary_section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'image_url' AND data_type = 'text')
            AND EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'menu-images' AND public = true)
            AND EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND cmd = 'INSERT' AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%'))
        THEN '✅ ALL CHECKS PASSED - Image storage should work!'
        ELSE '⚠️ SOME CHECKS FAILED - Review results above'
    END as overall_status;

