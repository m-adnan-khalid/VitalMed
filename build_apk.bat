@echo off
REM VitalSync APK Build Script for Windows
REM This script builds the Android APK for testing on your phone

echo 🏥 Building VitalSync APK for Android Testing...
echo =================================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Check Flutter doctor
echo 🔍 Checking Flutter setup...
flutter doctor

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Generate any necessary code
echo 🔨 Generating code...
flutter packages pub run build_runner build

REM Build debug APK for testing
echo 🔨 Building debug APK...
flutter build apk --debug --target-platform android-arm,android-arm64,android-x64

REM Check if build was successful
if %errorlevel% equ 0 (
    echo ✅ APK built successfully!
    echo.
    echo 📍 APK Location:
    echo    build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo 📱 Installation Instructions:
    echo 1. Enable 'Developer Options' on your Android phone
    echo 2. Enable 'USB Debugging'
    echo 3. Connect phone via USB
    echo 4. Run: adb install build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo Or copy the APK to your phone and install manually
    echo (Enable 'Install from Unknown Sources' in Settings)
    echo.
    echo 🔐 Required Permissions on Phone:
    echo - Bluetooth
    echo - Location (for BLE scanning)
    echo - Storage (for local data)
    echo.
    
    REM Create installation batch file
    echo @echo off > install_apk.bat
    echo echo 📱 Installing VitalSync APK... >> install_apk.bat
    echo adb devices >> install_apk.bat
    echo echo If your device appears above, installing APK... >> install_apk.bat
    echo adb install -r build\app\outputs\flutter-apk\app-debug.apk >> install_apk.bat
    echo echo ✅ Installation complete! Check your phone. >> install_apk.bat
    echo pause >> install_apk.bat
    
    echo 📲 Run 'install_apk.bat' to install via ADB
    
) else (
    echo ❌ Build failed!
    echo Check the error messages above and fix any issues.
    echo.
    echo Common solutions:
    echo - Run: flutter doctor --android-licenses
    echo - Update Android SDK
    echo - Check internet connection for dependencies
    pause
    exit /b 1
)

echo.
echo 🎉 VitalSync is ready for testing!
echo The APK includes full BLE health monitoring capabilities.
pause