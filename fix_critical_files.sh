#!/bin/bash

echo "🚀 SAINTE APP - CRITICAL FILES FIX"
echo "==================================="
echo "Fixing only the most critical files first"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Fix 1: Splash screen
echo "🔧 Fixing splash screen..."
sed -i '' 's/accountState\.name/accountState.fullName/g' lib/ui/modules/splash/splash_screen.dart
echo "✅ Fixed splash screen"

# Fix 2: Admin dashboard
echo "🔧 Fixing admin dashboard..."
sed -i '' 's/accountState\.name/accountState.fullName/g' lib/ui/modules/admin/dashboard.dart
echo "✅ Fixed admin dashboard"

# Fix 3: Feeling screen
echo "🔧 Fixing feeling screen..."
sed -i '' 's/state\?\.userId/state?.id/g' lib/ui/modules/root/feeling_screen.dart
echo "✅ Fixed feeling screen"

# Fix 4: Home navigation
echo "🔧 Fixing home navigation..."
sed -i '' 's/account\.userId/account.id/g' lib/ui/modules/root/navigations/home_navigation_screen.dart
echo "✅ Fixed home navigation"

# Fix 5: Import statements in critical files
echo "🔧 Fixing import statements..."

# Fix user_dto imports in critical files
find lib/ui/modules/splash -name "*.dart" -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
find lib/ui/modules/admin -name "*.dart" -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
find lib/ui/modules/root -name "*.dart" -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
find lib/ui/modules/authentication -name "*.dart" -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
echo "✅ Fixed import statements in critical files"

echo ""
echo "🎉 CRITICAL FILES FIXED!"
echo "========================"
echo "Testing with: flutter analyze"
echo ""
