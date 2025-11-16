# 🧪 Quick Image Upload Test

## Test Steps

1. **Open Browser Console** (F12)
2. **Clear the console** (click the 🚫 icon)
3. **Go to `/admin`**
4. **Edit any product** (click the Edit button)
5. **Scroll to "Product Image" section**
6. **Click "Choose File" and select an image**
7. **Watch the console** - you should see:
   ```
   📤 Uploading image to Supabase Storage: {...}
   ✅ Image uploaded successfully: {...}
   🖼️ Image changed in form: https://...
   🖼️ Updated formData.image_url: https://...
   ```
8. **Click "Save" button**
9. **Watch the console** - you should see:
   ```
   💾 Saving product update: {...}
   📤 Updating product in database: {...}
   ✅ Product updated in database: {...}
   ```

## What to Look For

### ✅ If you see ALL these logs:
The image should be saved! Check the website to see if it displays.

### ❌ If you see an error:
- **Storage error:** Bucket `menu-images` doesn't exist or isn't public
- **Database error:** RLS policy is blocking the update
- **No logs at all:** Image upload component isn't working

## Common Errors

### Error: "Bucket not found"
**Fix:** Create `menu-images` bucket in Supabase Storage (set to Public)

### Error: "new row violates row-level security policy"
**Fix:** Run this SQL:
```sql
CREATE POLICY "Allow product updates" ON products
FOR UPDATE USING (true) WITH CHECK (true);
```

### Error: "permission denied"
**Fix:** Check RLS policies or temporarily disable RLS for testing

## Manual Test

If automatic save doesn't work, try this:

1. **Upload image** - copy the URL from console (the `✅ Image uploaded successfully` log)
2. **Run this SQL** (replace with your product ID and the URL):
   ```sql
   UPDATE products 
   SET image_url = 'PASTE_THE_URL_HERE'
   WHERE id = 'YOUR_PRODUCT_ID'
   RETURNING id, name, image_url;
   ```
3. **Check if it saved:**
   ```sql
   SELECT id, name, image_url FROM products WHERE id = 'YOUR_PRODUCT_ID';
   ```

