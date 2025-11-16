# 🚨 URGENT: Fix Image Upload - Do This Now!

## The Problem
The Storage bucket `menu-images` doesn't exist, so uploads fail.

## Quick Fix (2 minutes)

### Step 1: Create the Storage Bucket

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Open SQL Editor**
   - Click **"SQL Editor"** in left sidebar
   - Click **"New Query"**

3. **Run the Bucket Creation Script**
   - Open file: `CREATE_STORAGE_BUCKET.sql`
   - Copy ALL the contents
   - Paste into SQL Editor
   - Click **"Run"** (or Cmd/Ctrl + Enter)

4. **Verify It Worked**
   - You should see a table showing the bucket details
   - Should show: `menu-images | menu-images | true | 5242880`

### Step 2: Test Upload

1. **Go to `/admin`**
2. **Edit any product**
3. **Upload an image**
4. **Check browser console** - should see:
   ```
   📤 Uploading image to Supabase Storage
   ✅ Image uploaded successfully
   ```

---

## Alternative: Manual Method (If Storage Still Doesn't Work)

If Storage upload still fails, you can use the **URL input method**:

1. **Upload image to Imgur** (https://imgur.com)
2. **Right-click image → Copy image address**
3. **In admin panel, click "Or Use URL"**
4. **Paste the URL**
5. **Click "Use URL"**
6. **Save the product**

This will work even without Supabase Storage!

---

## Verify Bucket Exists

Run this SQL to check:
```sql
SELECT id, name, public 
FROM storage.buckets 
WHERE id = 'menu-images';
```

If you see a result, the bucket exists! ✅

---

## Still Not Working?

1. **Check browser console** for the exact error
2. **Check Supabase Storage** - go to Storage → see if `menu-images` bucket is there
3. **Try the URL method** as a workaround

The bucket creation SQL should fix it! 🎯

