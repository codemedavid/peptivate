# 🔧 Fix Image Upload Not Saving - Complete Guide

## 🚨 Quick Fix Steps

### Step 1: Run the SQL Migration

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click **"SQL Editor"** in the left sidebar
   - Click **"New Query"**

3. **Run the Fix Script**
   - Open the file: `FIX_IMAGE_URL.sql` in this project
   - Copy ALL the contents
   - Paste into Supabase SQL Editor
   - Click **"Run"** (or press Cmd/Ctrl + Enter)

4. **Verify It Worked**
   - You should see messages like:
     - ✅ `image_url column already exists`
     - ✅ `image_url column is TEXT type`
   - Check the results table showing your products

---

## 🔍 Troubleshooting

### Issue 1: "Permission Denied" Error

**Problem:** Row Level Security (RLS) is blocking updates

**Solution:**

1. **Check RLS Status:**
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename = 'products';
   ```

2. **If RLS is enabled, create/update policy:**
   ```sql
   -- Allow updates to products table
   CREATE POLICY "Allow product updates" ON products
   FOR UPDATE
   USING (true)
   WITH CHECK (true);
   ```

3. **Or temporarily disable RLS for testing:**
   ```sql
   ALTER TABLE products DISABLE ROW LEVEL SECURITY;
   ```
   ⚠️ **Re-enable after testing!**

---

### Issue 2: Column Doesn't Exist

**Problem:** The `image_url` column is missing

**Solution:**
```sql
ALTER TABLE products ADD COLUMN image_url TEXT;
```

---

### Issue 3: Image Uploads But Doesn't Save

**Problem:** The image uploads to Storage but URL doesn't save to database

**Check:**
1. Open browser console (F12)
2. Upload an image
3. Look for these logs:
   - `📤 Uploading image to Supabase Storage`
   - `✅ Image uploaded successfully`
   - `🖼️ Image changed: [URL]`
   - `💾 Saving product update`
   - `📤 Updating product in database`
   - `✅ Product updated in database`

**If you see errors:**
- **Storage error:** Check that `menu-images` bucket exists and is Public
- **Database error:** Check RLS policies (see Issue 1)

---

### Issue 4: Storage Bucket Missing

**Problem:** `menu-images` bucket doesn't exist

**Solution:**

1. Go to **Storage** in Supabase Dashboard
2. Click **"New bucket"**
3. Name: `menu-images`
4. **Toggle "Public bucket" to ON** ✅
5. Click **"Create bucket"**

---

## ✅ Verification Steps

After running the SQL fix:

1. **Check Column Exists:**
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'products' 
   AND column_name = 'image_url';
   ```
   Should return: `image_url | text`

2. **Test Image Upload:**
   - Go to `/admin`
   - Edit a product
   - Upload an image
   - Click Save
   - Check browser console for success messages

3. **Verify Image Saved:**
   ```sql
   SELECT id, name, image_url 
   FROM products 
   WHERE image_url IS NOT NULL 
   LIMIT 5;
   ```

4. **Check Website:**
   - Go to homepage
   - Product should show the uploaded image

---

## 🎯 Complete Test

Run this to test the entire flow:

```sql
-- 1. Check column exists
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'products' 
AND column_name = 'image_url';

-- 2. Check current products
SELECT 
    id,
    name,
    CASE 
        WHEN image_url IS NULL THEN 'No image'
        WHEN image_url = '' THEN 'Empty'
        ELSE 'Has image: ' || LEFT(image_url, 50) || '...'
    END as status
FROM products
ORDER BY updated_at DESC
LIMIT 10;

-- 3. Test update (replace with actual product ID)
-- UPDATE products 
-- SET image_url = 'https://example.com/test.jpg'
-- WHERE id = 'YOUR-PRODUCT-ID-HERE'
-- RETURNING id, name, image_url;
```

---

## 📝 What the Fix Does

1. ✅ Ensures `image_url` column exists
2. ✅ Sets column type to TEXT (supports long Supabase Storage URLs)
3. ✅ Creates index for faster queries
4. ✅ Shows current product image status
5. ✅ Verifies column structure

---

## 🆘 Still Not Working?

1. **Check Browser Console** for JavaScript errors
2. **Check Supabase Logs:**
   - Go to: Logs → API
   - Look for errors when saving
3. **Verify Environment Variables:**
   - Check `.env` file has correct Supabase URL and key
4. **Test Direct Database Update:**
   ```sql
   UPDATE products 
   SET image_url = 'https://test.com/image.jpg'
   WHERE id = (SELECT id FROM products LIMIT 1)
   RETURNING *;
   ```
   If this works, the issue is in the app code, not the database.

---

## 📞 Need More Help?

Check these files:
- `src/components/AdminDashboard.tsx` - Save function
- `src/hooks/useMenu.ts` - Update function
- `src/hooks/useImageUpload.ts` - Upload function
- Browser console logs (F12)

