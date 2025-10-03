#!/bin/bash

echo "🚀 SAINTE APP - FIX CRITICAL PROPERTIES"
echo "======================================="
echo "Fixing only the most critical property mismatches"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Fix 1: .userId to .id (most common error)
echo "🔧 Fixing .userId to .id..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix 2: .name to .fullName (second most common error)
echo "🔧 Fixing .name to .fullName..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix 3: .avatar to .avatarUrl (third most common error)
echo "🔧 Fixing .avatar to .avatarUrl..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

echo ""
echo "🎉 CRITICAL PROPERTIES FIXED!"
echo "============================="
echo "Testing with: flutter analyze"
echo ""

