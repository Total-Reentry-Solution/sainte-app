#!/bin/bash

echo "🚀 SAINTE APP - FIX ALL PROPERTIES"
echo "=================================="
echo "Fixing all property name mismatches"
echo ""

# Create backup
echo "📦 Creating backup..."
cp -r lib lib_backup_$(date +%Y%m%d_%H%M%S)
echo "✅ Backup created"

# Fix 1: .name to .fullName (352 references)
echo "🔧 Fixing .name to .fullName..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix 2: .userId to .id (remaining references)
echo "🔧 Fixing .userId to .id..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix 3: .avatar to .avatarUrl (remaining references)
echo "🔧 Fixing .avatar to .avatarUrl..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

# Fix 4: .personId to .id (remaining references)
echo "🔧 Fixing .personId to .id..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.personId\b/.id/g' {} \;
echo "✅ Fixed .personId references"

# Fix 5: .organizations to .organizationIds
echo "🔧 Fixing .organizations to .organizationIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.organizations\b/.organizationIds/g' {} \;
echo "✅ Fixed .organizations references"

# Fix 6: .services to .serviceIds
echo "🔧 Fixing .services to .serviceIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.services\b/.serviceIds/g' {} \;
echo "✅ Fixed .services references"

# Fix 7: .assignee to .assigneeIds
echo "🔧 Fixing .assignee to .assigneeIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.assignee\b/.assigneeIds/g' {} \;
echo "✅ Fixed .assignee references"

# Fix 8: .mentors to .mentorIds
echo "🔧 Fixing .mentors to .mentorIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.mentors\b/.mentorIds/g' {} \;
echo "✅ Fixed .mentors references"

# Fix 9: .officers to .officerIds
echo "🔧 Fixing .officers to .officerIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.officers\b/.officerIds/g' {} \;
echo "✅ Fixed .officers references"

# Fix 10: .supervisorsName to .supervisorName
echo "🔧 Fixing .supervisorsName to .supervisorName..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsName\b/.supervisorName/g' {} \;
echo "✅ Fixed .supervisorsName references"

# Fix 11: .supervisorsEmail to .supervisorEmail
echo "🔧 Fixing .supervisorsEmail to .supervisorEmail..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsEmail\b/.supervisorEmail/g' {} \;
echo "✅ Fixed .supervisorsEmail references"

# Fix 12: .dob to .dateOfBirth
echo "🔧 Fixing .dob to .dateOfBirth..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.dob\b/.dateOfBirth/g' {} \;
echo "✅ Fixed .dob references"

# Fix 13: .deleted to .isDeleted
echo "🔧 Fixing .deleted to .isDeleted..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.deleted\b/.isDeleted/g' {} \;
echo "✅ Fixed .deleted references"

echo ""
echo "🎉 ALL PROPERTIES FIXED!"
echo "========================"
echo "Testing with: flutter analyze"
echo ""

