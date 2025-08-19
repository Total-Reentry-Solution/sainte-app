# Complete Database Migration Guide

## Overview
This migration script consolidates all the database setup and fixes into one comprehensive script. It creates all necessary tables, indexes, policies, and enables real-time functionality for your Supabase database.

## What This Migration Does

### 🗄️ Core Tables Created
- **user_profiles** - User account information and profile data
- **appointments** - Meeting/appointment management
- **blog_posts** - Blog content management
- **blog_requests** - Blog content requests
- **conversations** - Chat conversation metadata
- **messages** - Individual chat messages with real-time support
- **incidents** - Incident reporting system
- **reports** - General reporting system
- **questions** - Question management
- **persons** - Person entity management
- **person_goals** - Personal goal tracking
- **person_activities** - Activity tracking
- **moods** - Mood categories and icons
- **mood_logs** - User mood tracking
- **case_citizen_assignment** - Case manager to citizen assignments

### 🔗 Normalization Tables
- **user_mentors** - User-mentor relationships
- **appointment_attendees** - Appointment participation
- **appointment_orgs** - Organization involvement in appointments
- **blog_request_clients** - Blog request client relationships
- **conversation_members** - Conversation participation

### 🚀 Features Enabled
- **Real-time messaging** - Live chat functionality
- **Row Level Security (RLS)** - Secure data access
- **Automatic timestamps** - Created/updated tracking
- **Foreign key constraints** - Data integrity
- **Performance indexes** - Fast query execution

## How to Run

### 1. Open Supabase Dashboard
- Go to your Supabase project dashboard
- Navigate to **SQL Editor**

### 2. Run the Migration
- Copy the entire contents of `complete_database_migration.sql`
- Paste it into the SQL Editor
- Click **Run** to execute the migration

### 3. Verify Success
- Check the output for the success message: "✅ Database migration completed successfully!"
- Verify all tables were created by checking the table list output

## Important Notes

### ⚠️ Existing Data
- This migration uses `CREATE TABLE IF NOT EXISTS` to avoid conflicts
- Existing data will be preserved
- New columns will be added to existing tables where needed

### 🔐 Security
- Row Level Security (RLS) is enabled on all tables
- Users can only access their own data
- Case managers have appropriate permissions for their assignments

### 🎯 Real-time Messaging
- The `messages` table is enabled for real-time updates
- This allows live chat functionality in your Flutter app
- No additional configuration needed

## Post-Migration Steps

### 1. Storage Bucket Setup
If you plan to use profile pictures, create a storage bucket:
- Go to **Storage** in your Supabase dashboard
- Create a new bucket called `avatars`
- Set it to public access

### 2. Test Your App
- Run your Flutter app
- Test user registration and login
- Test messaging functionality
- Verify profile picture uploads work

### 3. Monitor Performance
- Check the **Logs** section for any errors
- Monitor **Database** performance metrics
- Verify RLS policies are working correctly

## Troubleshooting

### Common Issues

#### "Table already exists" errors
- These are normal and can be ignored
- The migration uses `IF NOT EXISTS` clauses

#### Permission errors
- Ensure you're running as a database owner
- Check that your Supabase project has the necessary extensions enabled

#### Real-time not working
- Verify the `supabase_realtime` publication exists
- Check that RLS policies allow proper access

### Getting Help
- Check the Supabase documentation
- Review the individual fix files in this directory
- Check the **Logs** section in your Supabase dashboard

## Rollback (If Needed)

If you need to rollback this migration:
1. **DO NOT** drop tables with existing data
2. Instead, drop only the new tables you added
3. Use the individual fix files to selectively remove components
4. Consider backing up your database before major changes

## Next Steps

After running this migration:
1. Update your Flutter app to use the new database schema
2. Test all functionality thoroughly
3. Consider adding more specific RLS policies if needed
4. Monitor database performance and optimize as needed

---

**Note**: This migration is designed to be safe and non-destructive. It will add new functionality without breaking existing features. 