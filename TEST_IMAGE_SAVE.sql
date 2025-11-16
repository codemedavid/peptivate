-- ============================================
-- TEST IMAGE URL SAVE - Run this to test
-- ============================================
-- This will help diagnose why image_url isn't saving

-- Step 1: Check if column exists and is correct type
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- Step 2: Check current products and their image_url values
SELECT 
    id,
    name,
    image_url,
    CASE 
        WHEN image_url IS NULL THEN 'NULL'
        WHEN image_url = '' THEN 'EMPTY STRING'
        ELSE 'HAS VALUE: ' || LEFT(image_url, 50)
    END as image_status,
    updated_at
FROM products
ORDER BY updated_at DESC
LIMIT 10;

-- Step 3: Test direct update (replace with your product ID)
-- Get a product ID first:
SELECT id, name FROM products LIMIT 1;

-- Then test update (replace YOUR_PRODUCT_ID_HERE with actual ID):
/*
UPDATE products 
SET image_url = 'https://test-image-url.com/example.jpg'
WHERE id = 'YOUR_PRODUCT_ID_HERE'
RETURNING id, name, image_url;
*/

-- Step 4: Check RLS policies that might block updates
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'products';

-- Step 5: Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'products';

-- Step 6: If RLS is blocking, temporarily disable it (FOR TESTING ONLY!)
-- Uncomment the line below to disable RLS temporarily:
-- ALTER TABLE products DISABLE ROW LEVEL SECURITY;

-- Step 7: Re-enable RLS after testing (IMPORTANT!)
-- ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Step 8: Check for any triggers that might interfere
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'products';

