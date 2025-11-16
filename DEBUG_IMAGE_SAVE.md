# 🔍 Debug Image Save Issue - Step by Step

## 🚨 Quick Diagnostic Steps

### Step 1: Check Browser Console

1. **Open Browser Console** (F12 or Cmd+Option+I)
2. **Go to `/admin`** and edit a product
3. **Upload an image**
4. **Look for these logs in order:**

```
📤 Uploading image to Supabase Storage: {folder: "menu-images", fileName: "...", fileSize: ...}
✅ Image uploaded successfully: {fileName: "...", publicUrl: "https://..."}
🖼️ Image changed in form: https://...
🖼️ Updated formData.image_url: https://...
💾 Saving product update: {id: "...", image_url: "https://...", fullPayload: {...}}
📤 Updating product in database: {id: "...", image_url: "https://...", fullPayload: {...}}
✅ Product updated in database: {id: "...", image_url: "https://...", fullData: {...}}
```

**If you see an error at any step, note it down!**

---

### Step 2: Run SQL Diagnostic

1. **Go to Supabase Dashboard → SQL Editor**
2. **Run `TEST_IMAGE_SAVE.sql`**
3. **Check the results:**

   - **Column exists?** Should show `image_url | text | NULL | YES`
   - **RLS enabled?** Check if `rls_enabled = true`
   - **RLS policies?** Check if there are policies blocking updates

---

### Step 3: Test Direct Database Update

1. **Get a product ID:**
   ```sql
   SELECT id, name FROM products LIMIT 1;
   ```

2. **Try updating directly:**
   ```sql
   UPDATE products 
   SET image_url = 'https://test.com/image.jpg'
   WHERE id = 'YOUR_PRODUCT_ID_HERE'
   RETURNING id, name, image_url;
   ```

3. **If this works:** The database is fine, issue is in the app
4. **If this fails:** Check RLS policies or permissions

---

### Step 4: Check RLS Policies

**If RLS is enabled and blocking updates:**

1. **Check current policies:**
   ```sql
   SELECT policyname, cmd, qual, with_check
   FROM pg_policies
   WHERE tablename = 'products';
   ```

2. **Create/Update policy to allow updates:**
   ```sql
   -- Allow updates to products (adjust based on your auth setup)
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

### Step 5: Verify Image URL Format

**Check what URL format is being saved:**

1. **In browser console, after upload, check:**
   ```javascript
   // The logged image_url should be a full URL like:
   // https://[project].supabase.co/storage/v1/object/public/menu-images/[filename]
   ```

2. **If it's a base64 string:** The upload didn't work, check Storage bucket
3. **If it's a URL:** The upload worked, check if it's being saved

---

### Step 6: Check Storage Bucket

1. **Go to Supabase Dashboard → Storage**
2. **Check if `menu-images` bucket exists**
3. **Check if it's set to Public** ✅
4. **Check if images are actually uploaded:**
   - Click on `menu-images` bucket
   - You should see uploaded image files

---

## 🐛 Common Issues & Fixes

### Issue 1: "Permission Denied" Error

**Problem:** RLS is blocking the update

**Fix:**
```sql
-- Option 1: Create policy
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);

-- Option 2: Temporarily disable RLS (for testing)
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
```

---

### Issue 2: Image Uploads But URL is NULL

**Problem:** The image uploads to Storage but URL doesn't save

**Check:**
- Browser console logs - is `image_url` in the payload?
- Network tab - is the UPDATE request being sent?
- Supabase logs - any errors in API logs?

**Fix:**
- The code now explicitly includes `image_url` in the payload
- Check if there's a database trigger or constraint blocking it

---

### Issue 3: "Bucket Not Found" Error

**Problem:** `menu-images` bucket doesn't exist

**Fix:**
1. Go to Storage → New bucket
2. Name: `menu-images`
3. Toggle **Public bucket** to ON ✅
4. Create bucket

---

### Issue 4: Image URL Saves But Doesn't Display

**Problem:** URL is saved but image doesn't show on website

**Check:**
1. Is the URL accessible? (try opening in browser)
2. Is it a Supabase Storage URL? (should start with `https://[project].supabase.co`)
3. Check browser console for image load errors
4. Check CORS settings in Supabase Storage

---

## 🔧 Manual Test

**Test the entire flow manually:**

1. **Upload image in admin** → Check console for URL
2. **Copy the URL from console**
3. **Run this SQL:**
   ```sql
   UPDATE products 
   SET image_url = 'PASTE_URL_HERE'
   WHERE id = 'YOUR_PRODUCT_ID'
   RETURNING *;
   ```
4. **Check if it saved:**
   ```sql
   SELECT id, name, image_url FROM products WHERE id = 'YOUR_PRODUCT_ID';
   ```
5. **Refresh website** → Does image show?

---

## 📊 What to Report

If it still doesn't work, provide:

1. **Browser console logs** (all the logs from Step 1)
2. **SQL test results** (from Step 2)
3. **Direct update test result** (from Step 3)
4. **RLS status** (from Step 4)
5. **Storage bucket status** (from Step 6)
6. **Any error messages** you see

---

## ✅ Expected Behavior

**When working correctly:**

1. ✅ Image uploads to Storage
2. ✅ URL is logged in console
3. ✅ URL is included in formData
4. ✅ URL is sent in UPDATE request
5. ✅ Database saves the URL
6. ✅ Product refreshes with new image
7. ✅ Website displays the image

**If any step fails, that's where the issue is!**

