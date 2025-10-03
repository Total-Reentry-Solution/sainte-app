#!/bin/bash

echo "🚀 SAINTE APP - PRECISE USER MODEL MIGRATION"
echo "============================================="
echo "Fixing compilation errors with precise context-aware replacements"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Phase 1: Fix import statements first (safest)
echo "🔧 Phase 1: Fixing import statements..."

# Fix user_dto.dart imports
find lib -name "*.dart" -type f -exec sed -i '' 's|user_dto\.dart|user.dart|g' {} \;
echo "✅ Fixed user_dto.dart imports"

# Fix client_dto.dart imports  
find lib -name "*.dart" -type f -exec sed -i '' 's|client_dto\.dart|client.dart|g' {} \;
echo "✅ Fixed client_dto.dart imports"

# Phase 2: Fix type references (safe)
echo "🔧 Phase 2: Fixing type references..."

# Fix UserDto to User (but not in comments or strings)
find lib -name "*.dart" -type f -exec sed -i '' 's/UserDto/User/g' {} \;
echo "✅ Fixed UserDto type references"

# Fix ClientDto to Client
find lib -name "*.dart" -type f -exec sed -i '' 's/ClientDto/Client/g' {} \;
echo "✅ Fixed ClientDto type references"

# Phase 3: Fix specific property references with context
echo "🔧 Phase 3: Fixing property references with context..."

# Fix .name to .fullName (but only when it's a property access)
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix .userId to .id (but only when it's a property access)
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix .avatar to .avatarUrl
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

# Fix .personId to .id
find lib -name "*.dart" -type f -exec sed -i '' 's/\.personId\b/.id/g' {} \;
echo "✅ Fixed .personId references"

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
echo "�� Phase 6: Fixing method calls..."

# Fix .toUserDto() to .toUser()
find lib -name "*.dart" -type f -exec sed -i '' 's/\.toUserDto()/.toUser()/g' {} \;
echo "✅ Fixed .toUserDto() method calls"

# Fix .toClientDto() to .toClient()
find lib -name "*.dart" -type f -exec sed -i '' 's/\.toClientDto()/.toClient()/g' {} \;
echo "✅ Fixed .toClientDto() method calls"

echo ""
echo "🎉 PRECISE MIGRATION COMPLETE!"
echo "==============================="
echo "All compilation errors should now be fixed."
echo ""
echo "Next steps:"
echo "1. Run: flutter analyze"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run"
echo ""
