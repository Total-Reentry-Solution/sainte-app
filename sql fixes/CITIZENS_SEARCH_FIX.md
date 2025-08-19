# Citizens Search Fix

## The Problem
The search functionality isn't working because there are likely no citizens in the database or the data isn't being fetched properly.

## Step-by-Step Solution

### Step 1: Run Database Migration
1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the entire contents** of `add_test_citizens_migration.sql`
4. **Click Run** to execute the migration

This will:
- ✅ Add necessary fields to the persons table
- ✅ Insert 10 test citizens with different names and emails
- ✅ Verify the data was inserted correctly

### Step 2: Test the Database
After running the migration, run this query to verify citizens exist:

```sql
SELECT 
  COUNT(*) as total_citizens,
  COUNT(CASE WHEN case_status = 'intake' THEN 1 END) as intake_citizens,
  COUNT(CASE WHEN case_status = 'active' THEN 1 END) as active_citizens
FROM persons 
WHERE account_status = 'active';
```

You should see at least 10 citizens.

### Step 3: Check the Application
1. **Refresh your browser** (Ctrl+F5)
2. **Navigate to the Citizens section**
3. **You should now see citizens in the table**

### Step 4: Test the Search
Try searching for:
- **"John"** - Should find "John Doe"
- **"jane"** - Should find "Jane Smith" (case insensitive)
- **"john.doe@example.com"** - Should find by email
- **"doe"** - Should find by last name

## Debug Information

If it's still not working, check the browser console for these messages:
- `Search query: "your_search_term"`
- `Total citizens: X`
- `Filtered citizens: Y`

## Expected Results

After running the migration:
- ✅ Citizens table should show 10 test citizens
- ✅ Search should work for names and emails
- ✅ Case-insensitive search
- ✅ Real-time filtering as you type

## Test Citizens Added

The migration adds these test citizens:
- John Doe (john.doe@example.com)
- Jane Smith (jane.smith@example.com)
- Mike Johnson (mike.johnson@example.com)
- Sarah Wilson (sarah.wilson@example.com)
- David Brown (david.brown@example.com)
- Emily Davis (emily.davis@example.com)
- Robert Miller (robert.miller@example.com)
- Lisa Garcia (lisa.garcia@example.com)
- James Martinez (james.martinez@example.com)
- Maria Anderson (maria.anderson@example.com)

**Run the migration and the search should work!** 