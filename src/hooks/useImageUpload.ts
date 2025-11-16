import { useState } from 'react';
import { supabase } from '../lib/supabase';

export const useImageUpload = (folder: string = 'menu-images') => {
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const uploadImage = async (file: File): Promise<string> => {
    let progressInterval: NodeJS.Timeout | null = null;
    let uploadTimeout: NodeJS.Timeout | null = null;
    
    try {
      setUploading(true);
      setUploadProgress(0);

      console.log('🚀 Starting upload process...', { fileName: file.name, fileSize: file.size, fileType: file.type });

      // Validate file type
      const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
      if (!allowedTypes.includes(file.type)) {
        throw new Error('Please upload a valid image file (JPEG, PNG, WebP, or GIF)');
      }

      // Validate file size (5MB limit)
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
        throw new Error('Image size must be less than 5MB');
      }

      // Generate unique filename
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;

      // Simulate upload progress
      progressInterval = setInterval(() => {
        setUploadProgress(prev => {
          if (prev >= 90) {
            if (progressInterval) clearInterval(progressInterval);
            return 90;
          }
          return prev + 10;
        });
      }, 100);

      // Create timeout promise
      const timeoutPromise = new Promise<never>((_, reject) => {
        uploadTimeout = setTimeout(() => {
          reject(new Error('Upload timeout - The storage bucket might not exist. Please run CREATE_STORAGE_BUCKET.sql in Supabase SQL Editor.'));
        }, 30000); // 30 second timeout
      });

      // Upload to Supabase Storage (using dynamic folder/bucket)
      console.log('📤 Uploading image to Supabase Storage:', { folder, fileName, fileSize: file.size });
      
      // First, check if bucket exists by trying to list it
      const bucketCheckPromise = supabase.storage
        .from(folder)
        .list('', { limit: 1 });
      
      const bucketCheckResult = await Promise.race([
        bucketCheckPromise,
        timeoutPromise
      ]);
      
      // Clear timeout if bucket check succeeded
      if (uploadTimeout) {
        clearTimeout(uploadTimeout);
        uploadTimeout = null;
      }
      
      if (bucketCheckResult.error) {
        if (progressInterval) clearInterval(progressInterval);
        console.error('❌ Bucket check failed:', bucketCheckResult.error);
        
        if (bucketCheckResult.error.message?.includes('not found') || bucketCheckResult.error.message?.includes('Bucket not found')) {
          throw new Error('Storage bucket "menu-images" not found!\n\nPlease run CREATE_STORAGE_BUCKET.sql in Supabase SQL Editor to create it.');
        }
        throw new Error(`Bucket error: ${bucketCheckResult.error.message}`);
      }

      console.log('✅ Bucket exists, proceeding with upload...');

      // Create new timeout for upload
      const uploadTimeoutPromise = new Promise<never>((_, reject) => {
        uploadTimeout = setTimeout(() => {
          reject(new Error('Upload timeout - The upload is taking too long. Please check your connection and try again.'));
        }, 30000); // 30 second timeout
      });

      // Now upload the file
      const uploadPromise = supabase.storage
        .from(folder)
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: false,
          contentType: file.type
        });

      const uploadResult = await Promise.race([
        uploadPromise,
        uploadTimeoutPromise
      ]);

      // Clear timeout if upload succeeded
      if (uploadTimeout) {
        clearTimeout(uploadTimeout);
        uploadTimeout = null;
      }
      if (progressInterval) clearInterval(progressInterval);
      setUploadProgress(100);

      if (uploadResult.error) {
        console.error('❌ Supabase Storage upload error:', uploadResult.error);
        console.error('❌ Error details:', {
          message: uploadResult.error.message,
          statusCode: uploadResult.error.statusCode,
          error: uploadResult.error
        });
        
        // Provide helpful error message
        if (uploadResult.error.message?.includes('Bucket not found') || uploadResult.error.message?.includes('not found')) {
          throw new Error('Storage bucket "menu-images" not found!\n\nPlease run CREATE_STORAGE_BUCKET.sql in Supabase SQL Editor.');
        } else if (uploadResult.error.message?.includes('new row violates row-level security') || uploadResult.error.message?.includes('row-level security')) {
          throw new Error('Storage policy error!\n\nPlease run CREATE_STORAGE_BUCKET.sql to set up policies.');
        } else {
          throw new Error(`Upload failed: ${uploadResult.error.message || 'Unknown error'}`);
        }
      }

      if (!uploadResult.data) {
        throw new Error('Upload failed: No data returned');
      }

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from(folder)
        .getPublicUrl(uploadResult.data.path);

      console.log('✅ Image uploaded successfully:', { fileName, publicUrl });
      return publicUrl;
    } catch (error) {
      console.error('❌ Error uploading image:', error);
      if (uploadTimeout) clearTimeout(uploadTimeout);
      if (progressInterval) clearInterval(progressInterval);
      throw error;
    } finally {
      setUploading(false);
      setTimeout(() => setUploadProgress(0), 1000);
    }
  };

  const deleteImage = async (imageUrl: string): Promise<void> => {
    try {
      // Extract file path from URL
      const urlParts = imageUrl.split('/');
      const fileName = urlParts[urlParts.length - 1];

      const { error } = await supabase.storage
        .from(folder)
        .remove([fileName]);

      if (error) {
        throw error;
      }
    } catch (error) {
      console.error('Error deleting image:', error);
      throw error;
    }
  };

  return {
    uploadImage,
    deleteImage,
    uploading,
    uploadProgress
  };
};