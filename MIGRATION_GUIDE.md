# 🔄 Firebase to Supabase Migration Guide

## 📋 Overview

This guide documents the migration of your Flutter app from Firebase to Supabase. The migration includes authentication, database operations, file storage, and real-time features.

## ✅ Completed Changes

### 1. **Dependencies Updated**
- ✅ Removed Firebase packages: `firebase_auth`, `firebase_core`, `cloud_firestore`, `firebase_messaging`, `firebase_storage`
- ✅ Added Supabase package: `supabase_flutter: ^1.10.25`

### 2. **Configuration Files**
- ✅ Created `lib/core/config/supabase_config.dart` - Centralized Supabase configuration
- ✅ Updated `lib/main.dart` - Replaced Firebase initialization with Supabase
- ✅ Removed `lib/domain/firebase_api.dart` - No longer needed

### 3. **Authentication Migration**
- ✅ Updated `lib/data/repository/auth/auth_repository.dart`
  - Replaced `FirebaseAuth` with `SupabaseConfig.auth`
  - Updated sign-in, sign-up, password reset methods
  - Added OAuth support for Google and Apple
  - Added helper methods for user profile management

- ✅ Updated `lib/ui/modules/authentication/bloc/authentication_bloc.dart`
  - Removed Firebase-specific OAuth credential handling
  - Updated to use Supabase OAuth flow
  - Updated logout method

### 4. **Database Operations Migration**
- ✅ Updated `lib/data/repository/blog/blog_repository.dart`
  - Replaced Firestore with Supabase database operations
  - Updated file upload to use Supabase Storage
  - Added comprehensive blog management methods

- ✅ Updated `lib/data/repository/user/user_repository.dart`
  - Replaced Firestore with Supabase database operations
  - Added user profile management methods
  - Added client management methods
  - Added statistics and search functionality

- ✅ Updated `lib/data/repository/verification/verification_repository.dart`
  - Replaced Firestore with Supabase database operations
  - Added verification request management
  - Added statistics and search functionality

### 5. **UI Components**
- ✅ Updated `lib/ui/components/web_sidebar_layout.dart`
  - Replaced Firebase auth state listener with Supabase
  - Updated authentication state management

## 🔧 Required Configuration

### 1. **Supabase Project Setup**

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from the project settings
3. Update `lib/core/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key';
```

### 2. **Database Schema**

Create the following tables in your Supabase database:

#### User Profiles Table
```sql
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  first_name TEXT,
  last_name TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  account_type TEXT,
  profile_photo_url TEXT,
  user_code TEXT,
  reason_for_account_deletion TEXT,
  deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Blog Posts Table
```sql
CREATE TABLE blog_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  category TEXT,
  image_url TEXT,
  author_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Blog Requests Table
```sql
CREATE TABLE blog_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  category TEXT,
  requested_by_id UUID REFERENCES user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Questions Table
```sql
CREATE TABLE questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  question TEXT NOT NULL,
  category TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Verification Requests Table
```sql
CREATE TABLE verification_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES user_profiles(id),
  question_id UUID REFERENCES questions(id),
  answer TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Clients Table
```sql
CREATE TABLE clients (
  id UUID REFERENCES user_profiles(id) PRIMARY KEY,
  name TEXT,
  avatar TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. **Storage Buckets**

Create the following storage buckets in Supabase:

1. **blog_images** - For blog post images
2. **profile_photos** - For user profile photos

### 4. **Row Level Security (RLS)**

Enable RLS on all tables and create appropriate policies:

```sql
-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Example policies (adjust based on your needs)
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can view blog posts" ON blog_posts
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create blog posts" ON blog_posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);
```

### 5. **OAuth Configuration**

Configure OAuth providers in your Supabase project:

1. Go to Authentication > Providers
2. Enable Google and Apple providers
3. Add your OAuth credentials
4. Configure redirect URLs for your app

## 🚀 Next Steps

### 1. **Test Authentication**
- Test email/password sign-up and sign-in
- Test Google OAuth
- Test Apple OAuth
- Test password reset

### 2. **Test Database Operations**
- Test user profile creation and updates
- Test blog post creation, reading, updating, deletion
- Test verification question management
- Test client management

### 3. **Test File Uploads**
- Test profile photo uploads
- Test blog image uploads

### 4. **Update Remaining Repositories**

You'll need to migrate these remaining repositories:

- `lib/data/repository/appointment/appointment_repository.dart`
- `lib/data/repository/messaging/messaging_repository.dart`
- `lib/data/repository/goals/goals_repository.dart`
- `lib/data/repository/activities/activity_repository.dart`
- `lib/data/repository/incidents/incident_repository.dart`
- `lib/data/repository/organizations/organization_repository.dart`

### 5. **Push Notifications**

Since Supabase doesn't have built-in push notifications, you'll need to:

1. Set up a third-party service like OneSignal or Expo Notifications
2. Create Supabase functions to trigger notifications
3. Update your notification logic

### 6. **Environment Configuration**

Create environment-specific configuration:

```dart
// lib/core/config/environment.dart
enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static Environment environment = Environment.dev;
  
  static String get supabaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'https://your-dev-project.supabase.co';
      case Environment.staging:
        return 'https://your-staging-project.supabase.co';
      case Environment.prod:
        return 'https://your-prod-project.supabase.co';
    }
  }
  
  static String get supabaseAnonKey {
    switch (environment) {
      case Environment.dev:
        return 'your-dev-anon-key';
      case Environment.staging:
        return 'your-staging-anon-key';
      case Environment.prod:
        return 'your-prod-anon-key';
    }
  }
}
```

## 🔍 Testing Checklist

- [ ] User registration and login
- [ ] OAuth sign-in (Google, Apple)
- [ ] Password reset
- [ ] User profile management
- [ ] Blog post CRUD operations
- [ ] File uploads
- [ ] Verification system
- [ ] Client management
- [ ] Real-time features (if any)
- [ ] Error handling
- [ ] Offline functionality

## 🐛 Common Issues

### 1. **OAuth Redirect Issues**
- Ensure redirect URLs are properly configured in Supabase
- For mobile apps, use deep links: `io.supabase.flutter://login-callback/`

### 2. **RLS Policy Issues**
- Check that your RLS policies allow the operations you're trying to perform
- Test with different user roles

### 3. **Storage Permission Issues**
- Ensure storage buckets have proper policies
- Check that users have permission to upload files

### 4. **Database Connection Issues**
- Verify your Supabase URL and anon key
- Check that your database is accessible

## 📚 Additional Resources

- [Supabase Flutter Documentation](https://supabase.com/docs/reference/dart)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Supabase Database Documentation](https://supabase.com/docs/guides/database)
- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)

## 🎯 Migration Benefits

1. **Cost**: Supabase offers generous free tier and better pricing for scaling
2. **Performance**: PostgreSQL-based database with better query performance
3. **Features**: Built-in real-time subscriptions, edge functions, and more
4. **Open Source**: Self-hostable if needed
5. **SQL**: Full SQL access instead of NoSQL limitations

---

**Note**: This migration maintains the same functionality while switching to a more powerful and cost-effective backend solution. Make sure to thoroughly test all features after completing the migration. 