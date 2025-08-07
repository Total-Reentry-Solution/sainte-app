# Fix: Citizens are Clients

## The Issue
You're absolutely right! In this application, **citizens and clients are the same thing**. The error was occurring because the code was trying to query a separate `clients` table that doesn't exist, when it should be using the `user_profiles` table where citizens are stored.

## The Problem
The application was trying to query:
```sql
SELECT * FROM clients  -- This table doesn't exist!
```

When it should be querying:
```sql
SELECT * FROM user_profiles WHERE account_type = 'citizen'
```

## The Solution

### Step 1: Run the Database Migration

1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the entire contents** of `add_citizen_fields_migration.sql`
4. **Click Run** to execute the migration

This migration adds the missing fields that citizens/clients need:
- `assignees` - Array of assigned case managers
- `reason_for_request` - Why they need help
- `what_you_need_in_a_mentor` - Mentor requirements
- `dropped_reason` - Why they were dropped
- `client_id` - External client ID
- `status` - Current status (pending, active, dropped, decline)

### Step 2: Code Changes Made

I've updated the `ClientRepository` to:
- ✅ Query `user_profiles` table instead of non-existent `clients` table
- ✅ Filter by `account_type = 'citizen'` to get only citizens
- ✅ Use proper field names that match the database schema

I've also updated the `ClientDto` class to:
- ✅ Properly map from `user_profiles` table structure
- ✅ Handle `first_name` + `last_name` → `name` conversion
- ✅ Use `avatar_url` field instead of `avatar`
- ✅ Handle all the citizen-specific fields

## How It Works Now

### Database Structure
```sql
-- Citizens are stored in user_profiles table
user_profiles {
  id: "user-uuid",
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  account_type: "citizen",  -- This identifies them as a citizen/client
  assignees: ["case-manager-uuid"],  -- Assigned case managers
  reason_for_request: "Need help with job search",
  what_you_need_in_a_mentor: "Career guidance",
  status: "pending",
  avatar_url: "https://example.com/avatar.jpg"
}
```

### Application Logic
- **Citizens** = Users with `account_type = 'citizen'`
- **Case Managers** = Users with `account_type = 'case_manager'`
- **Clients** = Same as citizens (just different terminology)
- **Client Repository** = Queries citizens from `user_profiles` table

## Expected Results

After running the migration:
- ✅ No more "clients table does not exist" error
- ✅ Citizens section will load properly
- ✅ Case managers can view and manage citizens/clients
- ✅ All client functionality will work using the existing user_profiles table

## Verification

Run this query to see your citizens/clients:
```sql
SELECT 
  id, 
  first_name, 
  last_name, 
  email, 
  account_type, 
  status,
  assignees
FROM user_profiles 
WHERE account_type = 'citizen';
```

**The application should now work correctly with citizens stored as clients in the user_profiles table!** 