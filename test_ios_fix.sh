#!/bin/bash

echo "🔧 Testing the fixed iOS app..."

# Navigate to project directory
cd "$(dirname "$0")"

echo "🧹 Cleaning Flutter cache..."
flutter clean
flutter pub get

echo "🔄 Rebuilding iOS dependencies..."
cd ios
pod install --repo-update
cd ..

echo "📱 Running on iOS simulator..."
flutter run -d ios --verbose

echo "✅ If no errors above, the RangeError should be fixed!"