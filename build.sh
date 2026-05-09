#!/bin/bash

# Exit on error
set -e

PROJECT_NAME="Swift Browser"
SCHEME="Swift Browser"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_NAME="Swift Browser.app"

echo "🔨 Building Swift Browser..."

# Build the project
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "$SCHEME" -configuration Debug build

# Find the built app in DerivedData
APP_PATH=$(find "$DERIVED_DATA" -path "*/Build/Products/Debug/${APP_NAME}" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app in DerivedData"
    exit 1
fi

echo "✅ Build succeeded at: $APP_PATH"

# Copy to Applications
echo "📋 Copying to /Applications..."
cp -R "$APP_PATH" /Applications/
echo "✅ Copied to /Applications"

# Local codesign (ad-hoc)
echo "🔏 Codesigning with ad-hoc signature..."
codesign --force --deep --sign - /Applications/"$APP_NAME"
echo "✅ Codesign complete"

echo "🎉 Done! Launch Swift Browser from /Applications"