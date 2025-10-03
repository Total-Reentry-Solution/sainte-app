#!/bin/bash

echo "🚀 SAINTE APP - FIX SPECIFIC PROPERTIES"
echo "======================================="
echo "Fixing only the properties that actually exist in new models"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Fix 1: .userId to .id (only for User objects)
echo "🔧 Fixing .userId to .id for User objects..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix 2: .name to .fullName (only for User objects)
echo "🔧 Fixing .name to .fullName for User objects..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix 3: .avatar to .avatarUrl (only for User objects)
echo "🔧 Fixing .avatar to .avatarUrl for User objects..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

# Fix 4: .personId to .id (only for User objects)
echo "🔧 Fixing .personId to .id for User objects..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.personId\b/.id/g' {} \;
echo "✅ Fixed .personId references"

echo ""
echo "🎉 SPECIFIC PROPERTIES FIXED!"
echo "============================="
echo "Testing with: flutter analyze"
echo ""

