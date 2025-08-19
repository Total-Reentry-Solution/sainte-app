# Profile Picture Setup Guide

## The Problem
The database doesn't have a field for profile pictures, and the profile code isn't working properly.

## The Solution

### Step 1: Run the Database Migration
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `sql fixes/fix_profile_picture_migration.sql`
4. Click Run to execute the migration

This will:
- ✅ Add the `avatar_url` field to the `user_profiles` table
- ✅ Set up proper RLS policies for avatar access
- ✅ Create indexes for better performance
- ✅ Set default avatars for existing users

### Step 2: Create Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Click "Create bucket"
3. Name: `avatars`
4. Public bucket: ✅ Check this
5. Click "Create bucket"

### Step 3: Set Storage Policies
1. Go to Storage → avatars → Policies
2. Add these policies:

**Policy 1: "Anyone can view avatars"**
- Operation: SELECT
- Policy definition: `true`

**Policy 2: "Authenticated users can upload avatars"**
- Operation: INSERT
- Policy definition: `auth.role() = 'authenticated'`

**Policy 3: "Users can update their own avatars"**
- Operation: UPDATE
- Policy definition: `auth.uid()::text = (storage.foldername(name))[1]`

**Policy 4: "Users can delete their own avatars"**
- Operation: DELETE
- Policy definition: `auth.uid()::text = (storage.foldername(name))[1]`

### Step 4: Test the Functionality
1. Try updating a profile picture in your app
2. Check if the image appears in the Storage → avatars section
3. Verify the `avatar_url` field is updated in the `user_profiles` table

## What Was Fixed

### Database Issues:
- ✅ Added missing `avatar_url` field
- ✅ Set up proper RLS policies
- ✅ Added performance indexes
- ✅ Set default avatars for existing users

### Code Issues:
- ✅ Fixed file upload method to handle web files properly
- ✅ Improved error handling in upload methods
- ✅ Fixed temporary file creation for web uploads

## Troubleshooting

### If uploads still fail:
1. Check Supabase Storage logs
2. Verify the `avatars` bucket exists and is public
3. Check RLS policies are correctly set
4. Ensure the user is authenticated

### If images don't display:
1. Check the `avatar_url` field in the database
2. Verify the URL is accessible
3. Check if the storage bucket is public

## Next Steps
After running the migration and setting up storage:
1. Test profile picture upload in your app
2. Verify images are stored in Supabase Storage
3. Check that profile pictures display correctly
4. Test both mobile and web upload functionality

