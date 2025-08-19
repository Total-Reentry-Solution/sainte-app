# Fix for Missing Clients Table

## Problem
The application is showing this error:
```
Error: PostgrestException(message: relation "public.clients" does not exist, code: 42P01)
```

This happens because the `clients` table is missing from your database.

## Solution

### Step 1: Run the Database Migration

1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the entire contents** of `fix_missing_clients_table.sql`
4. **Click Run** to execute the migration

This migration will:
- ✅ Create the missing `clients` table
- ✅ Add missing fields to `user_profiles` table
- ✅ Create necessary indexes for performance
- ✅ Set up proper triggers and permissions
- ✅ Insert sample data for testing

### Step 2: Verify the Migration Worked

Run this query in Supabase SQL Editor to verify the table was created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'clients';
```

### Step 3: Test the Application

1. **Refresh your browser** (Ctrl+F5)
2. **Navigate to the Citizens section** in your app
3. **The error should be gone** and you should see the citizens/clients list

## What the Migration Does

### 1. Creates the `clients` table with these fields:
- `id` - Unique identifier
- `name` - Client name
- `avatar` - Profile picture URL
- `email` - Client email
- `reason_for_request` - Why they need help
- `what_you_need_in_a_mentor` - Mentor requirements
- `assignees` - Array of assigned case managers
- `dropped_reason` - Why they were dropped
- `client_id` - External client ID
- `status` - Current status (pending, active, dropped, decline)
- `created_at` / `updated_at` - Timestamps

### 2. Adds missing fields to `user_profiles`:
- `organizations` - Array of organization IDs
- `account_type` - User type (citizen, case_manager, etc.)
- `organization` - Organization name
- `organization_address` - Organization address
- `job_title` - Job title
- `supervisors_name` - Supervisor name
- `supervisors_email` - Supervisor email
- `services` - Array of services provided

### 3. Creates performance indexes:
- Index on client status
- Index on client assignees
- Index on user account type
- Index on user organizations

### 4. Sets up proper permissions:
- Grants authenticated users access to clients table
- Grants authenticated users access to user_profiles table

## Expected Results

After running the migration:
- ✅ No more "clients table does not exist" error
- ✅ Citizens section should load properly
- ✅ Case managers can view and manage clients
- ✅ Organization joining should work
- ✅ All case manager functionality should work

## Troubleshooting

### If you still get errors:
1. **Check if the migration ran successfully** - Look for any error messages
2. **Verify table exists** - Run the verification query above
3. **Clear browser cache** - Ctrl+Shift+Delete
4. **Refresh the page** - Ctrl+F5

### If the migration fails:
1. **Check for syntax errors** - Make sure you copied the entire migration
2. **Check permissions** - Make sure you have admin access to your Supabase project
3. **Try running in parts** - Split the migration into smaller sections

## Code Changes Made

I also fixed the `ClientDto` class to:
- ✅ Handle both camelCase and snake_case field names
- ✅ Properly convert between database and application formats
- ✅ Handle missing or null values gracefully

**Run the migration and the application should work properly!** 