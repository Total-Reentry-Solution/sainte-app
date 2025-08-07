# Supabase Setup Guide

This guide will help you set up Supabase for the Sainte app authentication and database needs.

## Prerequisites

1. A Supabase account (sign up at https://supabase.com)
2. Flutter project with `supabase_flutter` package installed

## Step 1: Create a Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Choose your organization
4. Enter project details:
   - Name: `sainte-app` (or your preferred name)
   - Database Password: Choose a strong password
   - Region: Select the region closest to your users
5. Click "Create new project"

## Step 2: Get Your Project Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy the following values:
   - Project URL
   - Anon (public) key
   - Service role key (keep this secret)

## Step 3: Update Your Flutter App

1. Open `lib/main.dart`
2. Update the Supabase initialization with your credentials:

```dart
if (kIsWeb) {
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  // ... rest of the code
}
```

## Step 4: Set Up Database Schema

1. In your Supabase dashboard, go to SQL Editor
2. Copy and paste the contents of `supabase_schema.sql`
3. Click "Run" to execute the SQL

This will create:
- `users` table with all necessary fields
- Row Level Security (RLS) policies
- Automatic triggers for user creation and updates
- Indexes for better performance

## Step 5: Configure Authentication

1. In Supabase dashboard, go to Authentication > Settings
2. Configure your site URL (e.g., `http://localhost:3000` for development)
3. Add redirect URLs for OAuth providers if needed

### OAuth Providers (Optional)

To enable Google and Apple sign-in:

#### Google OAuth
1. Go to Authentication > Providers
2. Enable Google provider
3. Add your Google OAuth credentials (Client ID and Secret)

#### Apple OAuth
1. Go to Authentication > Providers
2. Enable Apple provider
3. Add your Apple OAuth credentials

## Step 6: Test the Setup

1. Run your Flutter app: `flutter run -d chrome`
2. Try to create a new account
3. Try to sign in with existing credentials
4. Check the Supabase dashboard to see if users are being created

## Step 7: Environment Variables (Recommended)

For better security, use environment variables instead of hardcoding credentials:

1. Create a `.env` file in your project root:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

2. Update `lib/main.dart` to use environment variables:

```dart
if (kIsWeb) {
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
}
```

3. Run with environment variables:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

## Database Schema Details

The `users` table includes the following fields:

- `id`: UUID primary key (matches Supabase auth user ID)
- `email`: User's email address
- `name`: User's full name
- `phone_number`: User's phone number
- `address`: User's address
- `account_type`: Type of account (citizen, admin, etc.)
- `user_code`: Unique user code
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp
- `deleted`: Soft delete flag
- `push_notification_token`: FCM token for notifications
- `settings`: JSON object for user settings
- `reason_for_account_deletion`: Reason if account is deleted
- `organization`: Organization name (for org accounts)
- `organization_address`: Organization address
- `job_title`: User's job title
- `supervisors_name`: Supervisor's name
- `supervisors_email`: Supervisor's email
- `dob`: Date of birth
- `services`: Array of services the user has access to

## Security Features

- **Row Level Security (RLS)**: Users can only access their own data
- **Admin Access**: Admins can view all users
- **Automatic Timestamps**: `created_at` and `updated_at` are managed automatically
- **Soft Deletes**: Users are marked as deleted rather than removed from database

## Troubleshooting

### Common Issues

1. **CORS Errors**: Make sure your site URL is configured in Supabase Authentication settings
2. **RLS Policy Errors**: Check that the user is authenticated and policies are correctly set
3. **OAuth Redirect Issues**: Verify redirect URLs are correctly configured

### Debug Tips

1. Check the browser console for error messages
2. Use Supabase dashboard to monitor authentication events
3. Check the Network tab to see API requests
4. Use Supabase logs to debug server-side issues

## Next Steps

After setting up Supabase:

1. Test all authentication flows (sign up, sign in, password reset)
2. Implement additional features like user profile management
3. Set up real-time subscriptions if needed
4. Configure backup and monitoring

## Support

If you encounter issues:

1. Check the [Supabase documentation](https://supabase.com/docs)
2. Review the [Flutter Supabase package documentation](https://pub.dev/packages/supabase_flutter)
3. Check the project's GitHub issues for known problems 