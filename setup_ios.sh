#!/bin/bash

echo "🍎 Setting up Sainte app for iOS development on Mac..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install from Mac App Store first."
    exit 1
fi

echo "✅ Xcode found"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter found"

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "📦 Installing CocoaPods..."
    sudo gem install cocoapods
else
    echo "✅ CocoaPods found"
fi

# Navigate to project directory
cd "$(dirname "$0")"

echo "📱 Installing iOS dependencies..."
cd ios
pod install --repo-update
cd ..

echo "🔍 Checking Flutter doctor..."
flutter doctor

echo "🚀 Setup complete! You can now:"
echo "   1. Open ios/Runner.xcworkspace in Xcode"
echo "   2. Configure signing & capabilities"
echo "   3. Run 'flutter run -d ios' to launch on simulator"
echo "   4. Or run 'open -a Simulator' then 'flutter run'"

echo ""
echo "📋 Available simulators:"
flutter emulators