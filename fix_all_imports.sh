#!/bin/bash

echo "🚀 SAINTE APP - FIX ALL IMPORTS"
echo "================================"
echo "Fixing all import statements from old DTOs to new models"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Fix all user_dto.dart imports
echo "🔧 Fixing user_dto.dart imports..."
find lib -name "*.dart" -type f -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
echo "✅ Fixed user_dto.dart imports"

# Fix all client_dto.dart imports
echo "🔧 Fixing client_dto.dart imports..."
find lib -name "*.dart" -type f -exec sed -i '' 's|client_dto\.dart|client.dart|g' {} \;
echo "✅ Fixed client_dto.dart imports"

# Fix UserDto to User
echo "🔧 Fixing UserDto to User..."
find lib -name "*.dart" -type f -exec sed -i '' 's/UserDto/User/g' {} \;
echo "✅ Fixed UserDto to User"

# Fix ClientDto to Client
echo "🔧 Fixing ClientDto to Client..."
find lib -name "*.dart" -type f -exec sed -i '' 's/ClientDto/Client/g' {} \;
echo "✅ Fixed ClientDto to Client"

echo ""
echo "🎉 ALL IMPORTS FIXED!"
echo "====================="
echo "Testing with: flutter analyze"
echo ""
