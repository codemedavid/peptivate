# 🔧 Troubleshoot Image Storage - Step by Step

## 🎯 Quick Diagnosis

Follow these steps to identify and fix the exact issue:

---

## Step 1: Run the Fix Script

**First, run the comprehensive fix script:**

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Open `FIX_IMAGE_STORAGE.sql`
3. Copy all contents
4. Paste into SQL Editor
5. Click **"Run"** (or Cmd/Ctrl + Enter)
6. Review the verification results at the bottom

**If you see "ALL CHECKS PASSED"** → Skip to Step 3 (Test Upload)

**If you see warnings** → Continue to Step 2

---

## Step 2: Check Browser Console

1. Open your app at `http://localhost:5173/admin`
2. Open **Browser DevTools** (F12 or Cmd+Option+I)
3. Go to the **Console** tab
4. Edit a product and try to upload an image
5. Look for these specific error messages:

### Error: "Bucket not found" or "Bucket 'menu-images' not found"
**Solution:**
```sql
-- Run this in Supabase SQL Editor
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('menu-images', 'menu-images', true, 5242880, 
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
ON CONFLICT (id) DO UPDATE SET public = true;
```

### Error: "permission denied" or "new row violates row-level security"
**Solution:**
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'products';

-- If RLS is enabled (rowsecurity = true), create UPDATE policy:
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);
```

### Error: "column 'image_url' does not exist"
**Solution:**
```sql
ALTER TABLE products ADD COLUMN image_url TEXT;
```

### Error: "Upload timeout"
**Possible causes:**
- Bucket doesn't exist
- Network connection issue
- Storage policies blocking upload

**Solution:** Run `FIX_IMAGE_STORAGE.sql` to fix all issues

---

## Step 3: Test the Upload Flow

After running the fix script, test the complete flow:

1. **Go to `/admin`** in your app
2. **Edit any product**
3. **Click "Choose File"** and select an image
4. **Watch the browser console** - you should see:
   ```
   🚀 Starting image upload...
   📤 Uploading image to Supabase Storage
   ✅ Bucket exists, proceeding with upload...
   ✅ Image uploaded successfully
   🖼️ onImageChange callback received: [URL]
   ```
5. **Check if image preview appears** - the image should show immediately
6. **Click "Save"**
7. **Watch console** - you should see:
   ```
   💾 Saving product update
   📤 Updating product in database
   ✅ Product updated in database
   ✅ Image URL verified - matches what was sent
   ```
8. **Verify in database:**
   - Go to Supabase Dashboard → Table Editor → `products`
   - Find the product you just edited
   - Check if `image_url` column has a value

---

## Step 4: Verify Each Component

### ✅ Storage Bucket
```sql
SELECT id, name, public FROM storage.buckets WHERE id = 'menu-images';
```
**Expected:** Should return one row with `public = true`

### ✅ Storage Policies
```sql
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects' 
AND (policyname LIKE '%menu-images%' OR policyname LIKE '%menu%');
```
**Expected:** Should see policies for SELECT, INSERT, UPDATE, DELETE

### ✅ Database Column
```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'products' AND column_name = 'image_url';
```
**Expected:** Should return `image_url | text`

### ✅ RLS Policy (if RLS is enabled)
```sql
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'products' AND cmd = 'UPDATE';
```
**Expected:** Should return at least one UPDATE policy

---

## Step 5: Common Issues & Solutions

### Issue: Image uploads but doesn't save to database

**Symptoms:**
- Image preview appears
- Console shows "✅ Image uploaded successfully"
- But `image_url` is NULL in database after save

**Diagnosis:**
1. Check console for errors during save
2. Look for "permission denied" or RLS errors
3. Check if `image_url` is in the update payload (console log shows it)

**Solution:**
```sql
-- Create/update RLS UPDATE policy
DROP POLICY IF EXISTS "Allow product updates" ON products;
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);
```

---

### Issue: Upload fails immediately

**Symptoms:**
- Error appears right after selecting file
- Console shows "Bucket not found" or timeout

**Solution:**
```sql
-- Create bucket and policies
-- Run FIX_IMAGE_STORAGE.sql
```

---

### Issue: Image shows in preview but disappears after save

**Symptoms:**
- Image preview works
- After clicking Save, image disappears
- Database shows `image_url = NULL`

**Diagnosis:**
- This is likely an RLS policy issue
- The update is being blocked

**Solution:**
```sql
-- Check RLS status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'products';

-- If RLS is enabled, create UPDATE policy
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);
```

---

## Step 6: Manual Verification

After fixing, manually verify:

1. **Upload an image** in admin panel
2. **Check Supabase Storage:**
   - Go to Storage → `menu-images` bucket
   - You should see your uploaded image file
3. **Check Database:**
   - Go to Table Editor → `products`
   - Find the product
   - `image_url` should contain a full URL like:
     `https://[project].supabase.co/storage/v1/object/public/menu-images/[filename]`
4. **Check Frontend:**
   - Go to the main site (not admin)
   - Product should display the image

---

## 🐛 Still Not Working?

If you've completed all steps and it's still not working:

1. **Check the exact error message** in browser console
2. **Run the diagnostic script:**
   ```sql
   -- Run DIAGNOSE_IMAGE_UPLOAD.sql
   ```
3. **Check Supabase logs:**
   - Go to Supabase Dashboard → Logs
   - Look for errors related to storage or database
4. **Try the URL method as workaround:**
   - Upload image to Imgur or similar
   - Use "Or Use URL" option in admin panel
   - Paste the URL directly

---

## ✅ Success Indicators

You'll know it's working when:

- ✅ Image preview appears immediately after upload
- ✅ Console shows "✅ Image uploaded successfully"
- ✅ Console shows "✅ Product updated in database"
- ✅ Database `image_url` column has a value
- ✅ Image displays on the frontend product page

---

## 📞 Quick Reference

**Most Common Fix:**
```sql
-- Run FIX_IMAGE_STORAGE.sql - fixes 90% of issues
```

**If RLS is blocking:**
```sql
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);
```

**If bucket missing:**
```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('menu-images', 'menu-images', true, 5242880, 
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']);
```

---

**Start with `FIX_IMAGE_STORAGE.sql` - it should fix everything!** 🎯

