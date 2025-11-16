-- ============================================
-- FIX IMAGE URL COLUMN FOR PRODUCTS
-- ============================================
-- Run this SQL in your Supabase SQL Editor to ensure image_url works properly
-- Go to: Supabase Dashboard → SQL Editor → New Query → Paste this → Run

-- Step 1: Ensure image_url column exists and is TEXT type (supports long URLs)
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
        RAISE NOTICE '✅ Added image_url column';
    ELSE
        RAISE NOTICE '✅ image_url column already exists';
    END IF;
    
    -- Ensure it's TEXT type (not VARCHAR with length limit)
    ALTER TABLE products ALTER COLUMN image_url TYPE TEXT;
    RAISE NOTICE '✅ image_url column is TEXT type (supports long URLs)';
END $$;

-- Step 2: Check current products and their image status
SELECT 
    id,
    name,
    CASE 
        WHEN image_url IS NULL THEN '❌ No image'
        WHEN image_url = '' THEN '❌ Empty image URL'
        ELSE '✅ Has image'
    END as image_status,
    image_url,
    updated_at
FROM products
ORDER BY updated_at DESC
LIMIT 10;

-- Step 3: Verify column structure
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- Step 4: Test update (optional - uncomment to test)
-- UPDATE products 
-- SET image_url = 'https://example.com/test-image.jpg'
-- WHERE id = (SELECT id FROM products LIMIT 1)
-- RETURNING id, name, image_url;

-- ============================================
-- IF YOU GET PERMISSION ERRORS:
-- ============================================
-- Check Row Level Security (RLS) policies:
-- 1. Go to: Authentication → Policies
-- 2. Find policies for 'products' table
-- 3. Ensure there's a policy allowing UPDATE operations
-- 
-- Or temporarily disable RLS for testing:
-- ALTER TABLE products DISABLE ROW LEVEL SECURITY;
-- (Re-enable after testing: ALTER TABLE products ENABLE ROW LEVEL SECURITY;)

