#!/bin/bash

# Exit on error
set -e

echo "--------------------------------------------------"
echo "🚀 Legacy App - Play Store Upload Script"
echo "--------------------------------------------------"

# Check if build exists
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

if [ ! -f "$AAB_PATH" ]; then
    echo "📦 Build not found. Generating App Bundle..."
    flutter build appbundle --release
else
    echo "✅ Found existing App Bundle: $AAB_PATH"
fi

# Navigate to android directory for Fastlane
cd android

# Check for JSON key
if [ ! -f "api-key.json" ]; then
    echo "❌ ERROR: 'android/api-key.json' not found."
    echo "Please place your Google Service Account JSON key in the android/ folder."
    exit 1
fi

# Ensure fastlane is in the PATH
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin"

echo "📤 Uploading to Play Store (Track: Internal)..."
fastlane upload_play_store

echo "--------------------------------------------------"
echo "✅ Upload Complete!"
echo "--------------------------------------------------"
