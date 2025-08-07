# Using Persons Table for Case Manager Assignments

## The New Approach

Instead of using a separate `client_assignees` table, we're now using the `persons` table directly with a `case_manager_id` field to assign case managers to citizens.

## How It Works

### Database Structure
```sql
-- persons table (citizens/clients)
persons {
  person_id: "person-uuid",
  first_name: "John",
  last_name: "Doe",
  email: "john@example.com",
  case_status: "intake",  -- intake, active, dropped, decline
  account_status: "active",
  case_manager_id: "case-manager-uuid"  -- Links to auth.users.id
}
```

### Application Logic
- **Citizens/Clients** = Records in `persons` table with `account_status = 'active'`
- **Case Managers** = Users in `auth.users` with `user_profiles.account_type = 'case_manager'`
- **Assignments** = Direct relationship via `case_manager_id` field in `persons` table

## What I've Fixed

### 1. Updated ClientRepository
- ✅ Removed dependency on non-existent `client_assignees` table
- ✅ Query `persons` table directly using `case_manager_id`
- ✅ Added search functionality by name/email
- ✅ Added methods to assign/remove case managers

### 2. New Methods Added
- `searchCitizens(String searchTerm)` - Search by first name, last name, or email
- `assignCaseManagerToCitizen(String citizenId, String caseManagerId)` - Assign case manager
- `removeCaseManagerFromCitizen(String citizenId)` - Remove assignment

### 3. Database Migration
- ✅ Ensures `persons` table has `case_manager_id` field
- ✅ Adds proper indexes for performance
- ✅ Inserts sample data for testing

## How to Use

### Step 1: Run the Migration
1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the entire contents** of `simple_persons_migration.sql`
4. **Click Run**

### Step 2: Test the Application
1. **Refresh your browser** (Ctrl+F5)
2. **Navigate to the Citizens section**
3. **The error should be gone**

### Step 3: Assign Case Managers
- Use the search functionality to find citizens
- Assign case managers using the new methods
- View assigned citizens in the case manager's dashboard

## Benefits of This Approach

1. **Simpler Structure**: No need for separate assignment table
2. **Direct Relationships**: Case manager ID directly in persons table
3. **Better Performance**: Fewer joins needed
4. **Easier to Maintain**: Less complex database schema
5. **Search Functionality**: Can search citizens by name/email

## Expected Results

After running the migration:
- ✅ No more "client_assignees table does not exist" error
- ✅ Citizens section will load properly
- ✅ Case managers can view their assigned citizens
- ✅ Search functionality works
- ✅ Assignment/unassignment works

**This approach is much simpler and more direct!** 