#!/bin/bash

echo "Cleaning up iOS project..."

# Clean Flutter
echo "Cleaning Flutter..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Clean iOS pods
echo "Cleaning iOS pods..."
cd ios
pod deintegrate
rm -rf Pods
rm -rf Podfile.lock

# Reinstall pods
echo "Reinstalling pods..."
pod install

echo "iOS cleanup complete!"
echo "You may need to open the iOS project in Xcode and clean build folder if you encounter any issues." 