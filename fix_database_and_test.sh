#!/bin/bash

echo "🔧 Sainte App Database Fix and Test Script"
echo "=========================================="

# Check if .env file exists and has proper values
echo "📋 Checking environment configuration..."
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Please create a .env file with your Supabase credentials:"
    echo "SUPABASE_URL=https://your-project-id.supabase.co"
    echo "SUPABASE_ANON_KEY=your-anon-key-here"
    echo "SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here"
    exit 1
fi

# Check if Supabase credentials are set
if grep -q "your-project-id" .env; then
    echo "⚠️  Please update your .env file with actual Supabase credentials"
    echo "Current .env contains placeholder values"
    exit 1
fi

echo "✅ Environment configuration looks good"

# Run Flutter analyze to check for code issues
echo "🔍 Running Flutter analyze..."
flutter analyze --no-fatal-infos

if [ $? -ne 0 ]; then
    echo "❌ Flutter analyze found issues. Please fix them before proceeding."
    exit 1
fi

echo "✅ Code analysis passed"

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to get dependencies"
    exit 1
fi

echo "✅ Dependencies updated"

# Test the build
echo "🏗️  Testing Flutter build..."
flutter build web --no-sound-null-safety

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"

# Run the app
echo "🚀 Starting Flutter app on localhost:8085..."
echo "📝 Note: You'll need to apply the database migration manually in your Supabase dashboard:"
echo "   1. Go to your Supabase project dashboard"
echo "   2. Navigate to SQL Editor"
echo "   3. Copy and paste the contents of 'sql fixes/complete_database_fix.sql'"
echo "   4. Click 'Run' to execute the migration"
echo ""
echo "🌐 App will be available at: http://localhost:8085"
echo "🛑 Press Ctrl+C to stop the server"
echo ""

flutter run -d chrome --web-port 8085

