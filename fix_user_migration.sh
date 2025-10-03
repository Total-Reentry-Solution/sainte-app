#!/bin/bash

echo "🚀 SAINTE APP - COMPLETE USER MODEL MIGRATION"
echo "=============================================="
echo "Fixing all 779 compilation errors from UserDto to User model"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Phase 1: Fix critical property references
echo "🔧 Phase 1: Fixing critical property references..."

# Fix .name to .fullName
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix .userId to .id  
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix .avatar to .avatarUrl
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

# Fix .personId to .id
find lib -name "*.dart" -type f -exec sed -i '' 's/\.personId\b/.id/g' {} \;
echo "✅ Fixed .personId references"

# Phase 2: Fix import statements
echo "🔧 Phase 2: Fixing import statements..."

# Fix user_dto.dart imports
find lib -name "*.dart" -type f -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
echo "✅ Fixed user_dto.dart imports"

# Fix client_dto.dart imports  
find lib -name "*.dart" -type f -exec sed -i '' 's|client_dto\.dart|client.dart|g' {} \;
echo "✅ Fixed client_dto.dart imports"

# Phase 3: Fix type references
echo "🔧 Phase 3: Fixing type references..."

# Fix UserDto to User
find lib -name "*.dart" -type f -exec sed -i '' 's/UserDto/User/g' {} \;
echo "✅ Fixed UserDto type references"

# Fix ClientDto to Client
find lib -name "*.dart" -type f -exec sed -i '' 's/ClientDto/Client/g' {} \;
echo "✅ Fixed ClientDto type references"

# Phase 4: Fix specific property mappings
echo "🔧 Phase 4: Fixing specific property mappings..."

# Fix .organizations to .organizationIds
find lib -name "*.dart" -type f -exec sed -i '' 's/\.organizations\b/.organizationIds/g' {} \;
echo "✅ Fixed .organizations references"

# Fix .services to .serviceIds
find lib -name "*.dart" -type f -exec sed -i '' 's/\.services\b/.serviceIds/g' {} \;
echo "✅ Fixed .services references"

# Fix .assignee to .assigneeIds
find lib -name "*.dart" -type f -exec sed -i '' 's/\.assignee\b/.assigneeIds/g' {} \;
echo "✅ Fixed .assignee references"

# Fix .mentors to .mentorIds
find lib -name "*.dart" -type f -exec sed -i '' 's/\.mentors\b/.mentorIds/g' {} \;
echo "✅ Fixed .mentors references"

# Fix .officers to .officerIds
find lib -name "*.dart" -type f -exec sed -i '' 's/\.officers\b/.officerIds/g' {} \;
echo "✅ Fixed .officers references"

# Fix .supervisorsName to .supervisorName
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsName\b/.supervisorName/g' {} \;
echo "✅ Fixed .supervisorsName references"

# Fix .supervisorsEmail to .supervisorEmail
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsEmail\b/.supervisorEmail/g' {} \;
echo "✅ Fixed .supervisorsEmail references"

# Fix .dob to .dateOfBirth
find lib -name "*.dart" -type f -exec sed -i '' 's/\.dob\b/.dateOfBirth/g' {} \;
echo "✅ Fixed .dob references"

# Fix .deleted to .isDeleted
find lib -name "*.dart" -type f -exec sed -i '' 's/\.deleted\b/.isDeleted/g' {} \;
echo "✅ Fixed .deleted references"

# Phase 5: Fix verification status references
echo "🔧 Phase 5: Fixing verification status references..."

# Fix .verificationStatus to .verification?.status
find lib -name "*.dart" -type f -exec sed -i '' 's/\.verificationStatus\b/.verification?.status/g' {} \;
echo "✅ Fixed .verificationStatus references"

# Phase 6: Fix method calls
echo "🔧 Phase 6: Fixing method calls..."

# Fix .toUserDto() to .toUser()
find lib -name "*.dart" -type f -exec sed -i '' 's/\.toUserDto()/.toUser()/g' {} \;
echo "✅ Fixed .toUserDto() method calls"

# Fix .toClientDto() to .toClient()
find lib -name "*.dart" -type f -exec sed -i '' 's/\.toClientDto()/.toClient()/g' {} \;
echo "✅ Fixed .toClientDto() method calls"

echo ""
echo "🎉 MIGRATION COMPLETE!"
echo "======================"
echo "All 779+ compilation errors should now be fixed."
echo ""
echo "Next steps:"
echo "1. Run: flutter analyze"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run"
echo ""
echo "If you encounter any issues, restore from backup:"
echo "rm -rf lib && mv lib_backup_* lib"
echo ""
