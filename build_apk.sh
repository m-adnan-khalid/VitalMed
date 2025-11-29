#!/bin/bash

# VitalSync APK Build Script
# This script builds the Android APK for testing on your phone

echo "🏥 Building VitalSync APK for Android Testing..."
echo "================================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter doctor
echo "🔍 Checking Flutter setup..."
flutter doctor

# Check if Android toolchain is available
if ! flutter doctor | grep -q "Android toolchain"; then
    echo "⚠️  Android toolchain not found"
    echo "Please install Android Studio and Android SDK"
    echo "Run: flutter doctor --android-licenses"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate any necessary code
echo "🔨 Generating code..."
flutter packages pub run build_runner build

# Build debug APK for testing
echo "🔨 Building debug APK..."
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ APK built successfully!"
    echo ""
    echo "📍 APK Location:"
    echo "   build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "📱 Installation Instructions:"
    echo "1. Enable 'Developer Options' on your Android phone"
    echo "2. Enable 'USB Debugging'"
    echo "3. Connect phone via USB"
    echo "4. Run: adb install build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "Or copy the APK to your phone and install manually"
    echo "(Enable 'Install from Unknown Sources' in Settings)"
    echo ""
    echo "🔐 Required Permissions on Phone:"
    echo "- Bluetooth"
    echo "- Location (for BLE scanning)"
    echo "- Storage (for local data)"
    echo ""
    
    # Get APK size
    APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-debug.apk | awk '{print $5}')
    echo "📊 APK Size: $APK_SIZE"
    
    # Create installation script
    cat > install_apk.sh << 'EOF'
#!/bin/bash
echo "📱 Installing VitalSync APK..."
adb devices
echo "If your device appears above, installing APK..."
adb install -r build/app/outputs/flutter-apk/app-debug.apk
echo "✅ Installation complete! Check your phone."
EOF
    chmod +x install_apk.sh
    echo "📲 Run './install_apk.sh' to install via ADB"
    
else
    echo "❌ Build failed!"
    echo "Check the error messages above and fix any issues."
    echo ""
    echo "Common solutions:"
    echo "- Run: flutter doctor --android-licenses"
    echo "- Update Android SDK"
    echo "- Check internet connection for dependencies"
    exit 1
fi

echo ""
echo "🎉 VitalSync is ready for testing!"
echo "The APK includes full BLE health monitoring capabilities."