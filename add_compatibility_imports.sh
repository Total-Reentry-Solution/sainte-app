#!/bin/bash

echo "🚀 SAINTE APP - ADD COMPATIBILITY IMPORTS"
echo "========================================="
echo "Adding compatibility imports to all files"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Add User compatibility import to files that import user.dart
echo "🔧 Adding User compatibility imports..."
find lib -name "*.dart" -type f -exec grep -l "import.*user\.dart" {} \; | while read file; do
  # Check if compatibility import already exists
  if ! grep -q "user_compatibility.dart" "$file"; then
    # Add import after the user.dart import
    sed -i '' '/import.*user\.dart/a\
import '\''package:reentry/data/model/user_compatibility.dart'\'';
' "$file"
    echo "✅ Added User compatibility to $file"
  fi
done

# Add Client compatibility import to files that import client.dart
echo "🔧 Adding Client compatibility imports..."
find lib -name "*.dart" -type f -exec grep -l "import.*client\.dart" {} \; | while read file; do
  # Check if compatibility import already exists
  if ! grep -q "client_compatibility.dart" "$file"; then
    # Add import after the client.dart import
    sed -i '' '/import.*client\.dart/a\
import '\''package:reentry/data/model/client_compatibility.dart'\'';
' "$file"
    echo "✅ Added Client compatibility to $file"
  fi
done

echo ""
echo "🎉 COMPATIBILITY IMPORTS ADDED!"
echo "==============================="
echo "Testing with: flutter analyze"
echo ""

