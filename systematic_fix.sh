#!/bin/bash

echo "🚀 SAINTE APP - SYSTEMATIC FIX"
echo "==============================="
echo "Fixing property mappings systematically"
echo ""

# Fix .name to .fullName (but be careful with context)
echo "🔧 Fixing .name to .fullName..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.name\b/.fullName/g' {} \;
echo "✅ Fixed .name references"

# Fix .userId to .id
echo "🔧 Fixing .userId to .id..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.userId\b/.id/g' {} \;
echo "✅ Fixed .userId references"

# Fix .avatar to .avatarUrl
echo "🔧 Fixing .avatar to .avatarUrl..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.avatar\b/.avatarUrl/g' {} \;
echo "✅ Fixed .avatar references"

# Fix .personId to .id
echo "🔧 Fixing .personId to .id..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.personId\b/.id/g' {} \;
echo "✅ Fixed .personId references"

# Fix .organizations to .organizationIds
echo "🔧 Fixing .organizations to .organizationIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.organizations\b/.organizationIds/g' {} \;
echo "✅ Fixed .organizations references"

# Fix .services to .serviceIds
echo "🔧 Fixing .services to .serviceIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.services\b/.serviceIds/g' {} \;
echo "✅ Fixed .services references"

# Fix .assignee to .assigneeIds
echo "🔧 Fixing .assignee to .assigneeIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.assignee\b/.assigneeIds/g' {} \;
echo "✅ Fixed .assignee references"

# Fix .mentors to .mentorIds
echo "🔧 Fixing .mentors to .mentorIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.mentors\b/.mentorIds/g' {} \;
echo "✅ Fixed .mentors references"

# Fix .officers to .officerIds
echo "🔧 Fixing .officers to .officerIds..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.officers\b/.officerIds/g' {} \;
echo "✅ Fixed .officers references"

# Fix .supervisorsName to .supervisorName
echo "🔧 Fixing .supervisorsName to .supervisorName..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsName\b/.supervisorName/g' {} \;
echo "✅ Fixed .supervisorsName references"

# Fix .supervisorsEmail to .supervisorEmail
echo "🔧 Fixing .supervisorsEmail to .supervisorEmail..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.supervisorsEmail\b/.supervisorEmail/g' {} \;
echo "✅ Fixed .supervisorsEmail references"

# Fix .dob to .dateOfBirth
echo "�� Fixing .dob to .dateOfBirth..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.dob\b/.dateOfBirth/g' {} \;
echo "✅ Fixed .dob references"

# Fix .deleted to .isDeleted
echo "🔧 Fixing .deleted to .isDeleted..."
find lib -name "*.dart" -type f -exec sed -i '' 's/\.deleted\b/.isDeleted/g' {} \;
echo "✅ Fixed .deleted references"

echo ""
echo "🎉 SYSTEMATIC FIX COMPLETE!"
echo "==========================="
echo "Testing with: flutter analyze"
echo ""
