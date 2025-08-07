# Fix: Use Persons Table for Clients/Citizens

## The Issue
You're absolutely right! The application should be using the `persons` table for clients/citizens, not `user_profiles`. The error was occurring because the code was trying to query fields that don't exist in the `user_profiles` table.

## The Correct Database Structure

### How It Should Work:
- **`user_profiles`** table: Contains basic user authentication info and links to `persons` via `person_id`
- **`persons`** table: Contains detailed person information including case management data
- **`client_assignees`** table: Links clients (persons) to case managers

### Database Schema:
```sql
-- user_profiles table (authentication)
user_profiles {
  id: "auth-user-uuid",
  first_name: "John",
  last_name: "Doe", 
  email: "john@example.com",
  person_id: "person-uuid",  -- Links to persons table
  avatar_url: "https://example.com/avatar.jpg"
}

-- persons table (detailed person data)
persons {
  person_id: "person-uuid",
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  case_status: "intake",  -- intake, active, dropped, decline
  account_status: "active",
  case_manager_id: "case-manager-uuid",
  date_of_birth: "1990-01-01",
  housing_status: "homeless",
  employment_status: "unemployed",
  justice_status: "probation"
}

-- client_assignees table (case manager assignments)
client_assignees {
  id: "assignment-uuid",
  client_id: "person-uuid",  -- References persons.person_id
  assignee_id: "case-manager-uuid",  -- References auth.users.id
  status: "active"
}
```

## The Solution

### Step 1: Run the Database Migration

1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the entire contents** of `fix_persons_table_migration.sql`
4. **Click Run** to execute the migration

This migration will:
- ✅ Ensure `persons` table has all necessary fields
- ✅ Create `client_assignees` table for case manager assignments
- ✅ Add proper indexes for performance
- ✅ Set up triggers and permissions
- ✅ Insert sample data for testing

### Step 2: Code Changes Made

I've updated the `ClientRepository` to:
- ✅ Query `persons` table instead of `user_profiles`
- ✅ Use `client_assignees` table for case manager relationships
- ✅ Filter by `account_status = 'active'` and `case_status`
- ✅ Use proper field names that match the database schema

I've also updated the `ClientDto` class to:
- ✅ Properly map from `persons` table structure
- ✅ Handle `first_name` + `last_name` → `name` conversion
- ✅ Map `case_status` to `ClientStatus` enum
- ✅ Use `person_id` as the primary identifier

## How It Works Now

### Application Logic:
- **Citizens/Clients** = Records in `persons` table with `account_status = 'active'`
- **Case Managers** = Users in `auth.users` with `user_profiles.account_type = 'case_manager'`
- **Client Assignments** = Records in `client_assignees` table linking persons to case managers
- **Client Repository** = Queries persons through client_assignees relationships

### Data Flow:
1. **Get Recommended Clients**: Query `client_assignees` → get `client_id`s → query `persons`
2. **Get User Clients**: Same as above but for specific case manager
3. **Get All Clients**: Query all `persons` with `account_status = 'active'`
4. **Update Client**: Update `persons` table using `person_id`

## Expected Results

After running the migration:
- ✅ No more "column assignees does not exist" error
- ✅ Citizens section will load properly
- ✅ Case managers can view and manage citizens/clients
- ✅ Proper separation between authentication (user_profiles) and person data (persons)
- ✅ Case manager assignments work through client_assignees table

## Verification

Run these queries to verify the setup:

```sql
-- Check persons table
SELECT 
  person_id, 
  first_name, 
  last_name, 
  email, 
  case_status,
  account_status
FROM persons 
WHERE account_status = 'active';

-- Check client_assignees table
SELECT 
  ca.id,
  ca.client_id,
  ca.assignee_id,
  ca.status,
  p.first_name,
  p.last_name
FROM client_assignees ca
JOIN persons p ON ca.client_id = p.person_id
WHERE ca.status = 'active';
```

## Benefits of This Approach

1. **Proper Separation**: Authentication data separate from person data
2. **Scalability**: Can handle complex person relationships
3. **Flexibility**: Easy to add more person-specific fields
4. **Performance**: Proper indexing and relationships
5. **Data Integrity**: Foreign key constraints ensure data consistency

**The application should now work correctly using the proper database structure!** 