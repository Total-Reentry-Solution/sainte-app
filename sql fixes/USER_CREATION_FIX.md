# User Creation Fix

## Problem
Users were getting this error when trying to create accounts:
```
Failed to create account in Supabase: Postgresql error: null value in column "person_id" of relation "user_profiles" violates not-null constraint
```

## Root Cause
The `user_profiles` table requires a `person_id` field that links to the `persons` table, but the account creation process wasn't properly creating this relationship.

## Solution

### 1. Database Changes
Run the migration `fix_user_creation_migration.sql` which:
- Makes `person_id` nullable (it will be set by trigger)
- Adds missing `organizations` and `account_type` fields
- Ensures the trigger function properly creates person records
- Sets up proper indexes for performance

### 2. Code Changes
Updated `AuthRepository.createAccount()` to:
- First create a person record
- Then create the user profile with the proper `person_id` link
- Handle the new `organizations` and `account_type` fields

Updated `AuthRepository.findUserById()` to:
- Read the new `account_type` and `organizations` fields
- Return complete user data

Updated `AuthRepository.updateUser()` to:
- Update the new `account_type` and `organizations` fields
- Maintain data consistency

## How to Apply

### Step 1: Run Database Migration
Execute `fix_user_creation_migration.sql` in your Supabase database:

1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the migration content
3. Click "Run"

### Step 2: Deploy Code Changes
The code changes have been made to:
- `lib/data/repository/auth/auth_repository.dart`

### Step 3: Test
Try creating a new account - the error should be resolved.

## What This Fixes

1. **Account Creation**: Users can now create accounts without the person_id constraint error
2. **Case Manager Joining**: The organizations field is now properly handled
3. **Account Types**: Different user types (citizen, case_manager, etc.) are properly stored
4. **Data Consistency**: Person records are properly linked to user profiles

## Files Modified

- `lib/data/repository/auth/auth_repository.dart`
- `fix_user_creation_migration.sql` (new)
- `USER_CREATION_FIX.md` (new) 