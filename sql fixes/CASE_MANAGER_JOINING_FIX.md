# Case Manager Joining Fix

## Problem
Case managers were unable to join organizations due to several database schema and code issues:

1. **Missing Database Fields**: The `user_profiles` table was missing the `organizations` and `account_type` fields
2. **Commented Out Code**: The `joinOrganization` method in `OrganizationRepository` was commented out
3. **Schema Mismatch**: The `UserDto.fromJson` method wasn't properly reading organization data from the database
4. **Account Type Issues**: Account types weren't being properly stored or retrieved

## Solution

### Database Changes
Run the migration file `fix_case_manager_joining_migration.sql` to add the missing fields:

```sql
-- Adds organizations and account_type fields to user_profiles table
-- Creates necessary indexes for performance
-- Initializes existing users with default values
```

### Code Changes Made

1. **OrganizationRepository.dart**:
   - Uncommented and fixed the `joinOrganization` method
   - Uncommented and fixed the `removeFromOrganization` method
   - Cleaned up the `findOrganizationByCode` method

2. **UserDto.dart**:
   - Fixed `fromJson` method to properly read `organizations` field
   - Fixed `fromJson` method to properly read `account_type` field
   - Updated `toJson` method to use correct field names
   - Updated constants to use correct field names

## How to Apply the Fix

1. **Run the Database Migration**:
   ```bash
   # Execute the migration in your Supabase database
   psql -h your-supabase-host -U your-username -d your-database -f fix_case_manager_joining_migration.sql
   ```

2. **Deploy the Code Changes**:
   - The code changes have been made to the repository
   - Deploy the updated code to your application

3. **Test the Fix**:
   - Try joining an organization as a case manager
   - Verify that the organization appears in the user's organizations list
   - Test removing from organizations

## Verification

After applying the fix, case managers should be able to:
- Join organizations using organization codes
- See their joined organizations in their profile
- Remove themselves from organizations
- Have their account type properly recognized

## Files Modified

- `lib/data/repository/org/organization_repository.dart`
- `lib/data/model/user_dto.dart`
- `fix_case_manager_joining_migration.sql` (new)
- `CASE_MANAGER_JOINING_FIX.md` (new) 