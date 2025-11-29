# 📱 Building VitalSync APK for Android Testing

## 🎯 Options to Get Your APK

### Option 1: Build Locally (Recommended)
If you have Android Studio and Flutter installed on your local machine:

```bash
# 1. Clone/download the project to your local machine
# 2. Open terminal in the project directory
# 3. Ensure Android SDK is installed
flutter doctor

# 4. Build debug APK for testing
flutter build apk --debug

# 5. Build release APK for distribution
flutter build apk --release

# APK will be located at: build/app/outputs/flutter-apk/app-debug.apk
```

### Option 2: Quick Setup Android SDK
Install Android command line tools and SDK:

```bash
# Install Android SDK command line tools
# Download from: https://developer.android.com/studio/index.html#cmdline-tools

# Set environment variables
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Accept licenses
flutter doctor --android-licenses

# Build APK
flutter build apk --release
```

### Option 3: Use GitHub Actions (Automated)
I can create a GitHub Actions workflow that automatically builds the APK:

```yaml
name: Build Android APK
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: actions/setup-java@v1
      with:
        java-version: '12.x'
    - uses: subosito/flutter-action@v1
      with:
        flutter-version: '3.38.3'
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v2
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

## 🛠️ Pre-Build Setup Required

### 1. Android Signing Configuration
Add to `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        debug {
            storeFile file('debug.keystore')
            storePassword 'android'
            keyAlias 'androiddebugkey'
            keyPassword 'android'
        }
    }
    buildTypes {
        debug {
            signingConfig signingConfigs.debug
        }
    }
}
```

### 2. App Permissions
Ensure these permissions are in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 3. Target SDK Configuration
Update `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.vitalsync.healthmonitor"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "2.0.0"
    }
}
```

## 🚀 Quick Build Commands

### For Testing (Debug)
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### For Distribution (Release)
```bash
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm,android-arm64
```

## 📁 APK Locations
- **Debug APK**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Installation on Phone

### Method 1: ADB Install
```bash
# Connect phone via USB with Developer Options enabled
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Method 2: Direct Transfer
1. Copy APK file to your phone
2. Enable "Install from Unknown Sources" in phone settings
3. Tap the APK file to install
4. Grant BLE permissions when prompted

## 🔐 Release Signing (For Production)

### 1. Generate Signing Key
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

### 2. Configure Gradle Signing
Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=key
storeFile=<path to key.jks>
```

### 3. Build Signed APK
```bash
flutter build apk --release
```

## 📋 APK Testing Checklist

✅ **Before Installing:**
- [ ] Phone has Android 5.0+ (API 21+)
- [ ] Bluetooth is enabled
- [ ] Location services enabled
- [ ] Unknown sources allowed

✅ **After Installing:**
- [ ] App launches successfully
- [ ] Permissions are granted
- [ ] BLE scanning works
- [ ] UI displays correctly
- [ ] Real-time features functional

## 🆘 Troubleshooting

### Common Issues:
1. **"App not installed"** - Enable unknown sources
2. **BLE not working** - Grant location permission
3. **App crashes** - Check Android version compatibility
4. **No devices found** - Ensure BLE device is in pairing mode

### Debug Commands:
```bash
flutter doctor -v
flutter analyze
flutter run --release
adb logcat | grep flutter
```

## 📞 Need Help?

If you encounter issues building the APK:
1. Share the error messages
2. Run `flutter doctor -v` and share output
3. Check Android SDK installation
4. Verify all dependencies are installed

The VitalSync app should work perfectly on Android devices with real BLE health monitoring devices!