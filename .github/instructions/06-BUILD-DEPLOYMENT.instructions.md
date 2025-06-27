---
applyTo: '**'
---

# 🚀 Build & Deployment - Complete Production Pipeline Guide

## 📋 Deployment Strategy Overview

This guide covers the complete build and deployment pipeline for the Revision Flutter application across all platforms (iOS, Android, Web) with multiple environments (development, staging, production).

## 🏗️ Build Configuration & Environment Management

### Environment Configuration

#### Environment Enum
```dart
// lib/core/config/environment.dart
enum Environment {
  development,
  staging,
  production,
}

class EnvConfig {
  static Environment _environment = Environment.development;
  
  static Environment get environment => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  static String get environmentName => _environment.name;
  
  // API Configuration
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://dev-api.revision.com';
      case Environment.staging:
        return 'https://staging-api.revision.com';
      case Environment.production:
        return 'https://api.revision.com';
    }
  }
  
  // AI Configuration
  static String get geminiApiKey {
    switch (_environment) {
      case Environment.development:
        return const String.fromEnvironment('GEMINI_API_KEY_DEV');
      case Environment.staging:
        return const String.fromEnvironment('GEMINI_API_KEY_STAGING');
      case Environment.production:
        return const String.fromEnvironment('GEMINI_API_KEY_PROD');
    }
  }
  
  // Firebase Configuration
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'revision-464202-dev';
      case Environment.staging:
        return 'revision-464202-staging';
      case Environment.production:
        return 'revision-464202';
    }
  }
  
  // Feature Flags
  static bool get enableAnalytics => !isDevelopment;
  static bool get enableCrashlytics => !isDevelopment;
  static bool get enablePerformanceMonitoring => isProduction;
  static bool get showDebugBanner => isDevelopment;
  
  // App Configuration
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'Revision Dev';
      case Environment.staging:
        return 'Revision Staging';
      case Environment.production:
        return 'Revision';
    }
  }
  
  static String get appSuffix {
    switch (_environment) {
      case Environment.development:
        return '.dev';
      case Environment.staging:
        return '.staging';
      case Environment.production:
        return '';
    }
  }
}
```

#### Environment-Specific Main Files
```dart
// lib/main_development.dart
import 'bootstrap.dart';
import 'core/config/environment.dart';

void main() {
  EnvConfig.setEnvironment(Environment.development);
  bootstrap();
}
```

```dart
// lib/main_staging.dart
import 'bootstrap.dart';
import 'core/config/environment.dart';

void main() {
  EnvConfig.setEnvironment(Environment.staging);
  bootstrap();
}
```

```dart
// lib/main_production.dart
import 'bootstrap.dart';
import 'core/config/environment.dart';

void main() {
  EnvConfig.setEnvironment(Environment.production);
  bootstrap();
}
```

### Build Scripts

#### PowerShell Build Scripts (Windows)
```powershell
# scripts/build-android.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("apk", "appbundle")]
    [string]$BuildType = "appbundle",
    
    [Parameter(Mandatory=$false)]
    [switch]$Release = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Environment-specific configuration
$envConfig = @{
    "development" = @{
        "target" = "lib/main_development.dart"
        "flavor" = "dev"
        "appId" = "com.example.revision.dev"
    }
    "staging" = @{
        "target" = "lib/main_staging.dart"
        "flavor" = "staging"
        "appId" = "com.example.revision.staging"
    }
    "production" = @{
        "target" = "lib/main_production.dart"
        "flavor" = "production"
        "appId" = "com.example.revision"
    }
}

$config = $envConfig[$Environment]
$buildMode = if ($Release) { "release" } else { "debug" }

Write-Host "🚀 Building Android $BuildType for $Environment environment in $buildMode mode..." -ForegroundColor Cyan

# Load environment variables
$envFile = ".env.$Environment"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

# Build command
$dartDefines = @(
    "ENVIRONMENT=$Environment",
    "GEMINI_API_KEY_DEV=$env:GEMINI_API_KEY_DEV",
    "GEMINI_API_KEY_STAGING=$env:GEMINI_API_KEY_STAGING",
    "GEMINI_API_KEY_PROD=$env:GEMINI_API_KEY_PROD"
)

$dartDefineArgs = $dartDefines | ForEach-Object { "--dart-define=$_" }

try {
    if ($BuildType -eq "apk") {
        flutter build apk `
            --target=$($config.target) `
            --flavor=$($config.flavor) `
            $(if ($Release) { "--release" } else { "--debug" }) `
            @dartDefineArgs
    } else {
        flutter build appbundle `
            --target=$($config.target) `
            --flavor=$($config.flavor) `
            $(if ($Release) { "--release" } else { "--debug" }) `
            @dartDefineArgs
    }
    
    Write-Host "✅ Android build completed successfully!" -ForegroundColor Green
    
    # Show output location
    $outputDir = "build/app/outputs/"
    if ($BuildType -eq "apk") {
        $outputDir += "flutter-apk/"
    } else {
        $outputDir += "bundle/$($config.flavor)Release/"
    }
    
    Write-Host "📦 Output location: $outputDir" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

```powershell
# scripts/build-ios.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("simulator", "device")]
    [string]$Destination = "device",
    
    [Parameter(Mandatory=$false)]
    [switch]$Release = $false
)

# macOS only check
if ($IsMacOS -ne $true) {
    Write-Host "❌ iOS builds are only supported on macOS" -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"

$envConfig = @{
    "development" = @{
        "target" = "lib/main_development.dart"
        "scheme" = "development"
        "bundleId" = "com.example.revision.dev"
    }
    "staging" = @{
        "target" = "lib/main_staging.dart"
        "scheme" = "staging"
        "bundleId" = "com.example.revision.staging"
    }
    "production" = @{
        "target" = "lib/main_production.dart"
        "scheme" = "Runner"
        "bundleId" = "com.example.revision"
    }
}

$config = $envConfig[$Environment]
$buildMode = if ($Release) { "release" } else { "debug" }

Write-Host "🚀 Building iOS for $Environment environment in $buildMode mode..." -ForegroundColor Cyan

# Load environment variables
$envFile = ".env.$Environment"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$dartDefines = @(
    "ENVIRONMENT=$Environment",
    "GEMINI_API_KEY_DEV=$env:GEMINI_API_KEY_DEV",
    "GEMINI_API_KEY_STAGING=$env:GEMINI_API_KEY_STAGING",
    "GEMINI_API_KEY_PROD=$env:GEMINI_API_KEY_PROD"
)

$dartDefineArgs = $dartDefines | ForEach-Object { "--dart-define=$_" }

try {
    if ($Destination -eq "simulator") {
        flutter build ios `
            --target=$($config.target) `
            --simulator `
            $(if ($Release) { "--release" } else { "--debug" }) `
            @dartDefineArgs
    } else {
        flutter build ios `
            --target=$($config.target) `
            $(if ($Release) { "--release" } else { "--debug" }) `
            @dartDefineArgs
    }
    
    Write-Host "✅ iOS build completed successfully!" -ForegroundColor Green
    Write-Host "📦 Output location: build/ios/" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

```powershell
# scripts/build-web.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [switch]$Release = $false
)

$ErrorActionPreference = "Stop"

$envConfig = @{
    "development" = @{
        "target" = "lib/main_development.dart"
        "baseHref" = "/dev/"
    }
    "staging" = @{
        "target" = "lib/main_staging.dart"
        "baseHref" = "/staging/"
    }
    "production" = @{
        "target" = "lib/main_production.dart"
        "baseHref" = "/"
    }
}

$config = $envConfig[$Environment]
$buildMode = if ($Release) { "release" } else { "debug" }

Write-Host "🚀 Building Web for $Environment environment in $buildMode mode..." -ForegroundColor Cyan

# Load environment variables
$envFile = ".env.$Environment"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

$dartDefines = @(
    "ENVIRONMENT=$Environment",
    "GEMINI_API_KEY_DEV=$env:GEMINI_API_KEY_DEV",
    "GEMINI_API_KEY_STAGING=$env:GEMINI_API_KEY_STAGING",
    "GEMINI_API_KEY_PROD=$env:GEMINI_API_KEY_PROD"
)

$dartDefineArgs = $dartDefines | ForEach-Object { "--dart-define=$_" }

try {
    flutter build web `
        --target=$($config.target) `
        --base-href=$($config.baseHref) `
        --web-renderer=canvaskit `
        $(if ($Release) { "--release" } else { "--debug" }) `
        @dartDefineArgs
    
    Write-Host "✅ Web build completed successfully!" -ForegroundColor Green
    Write-Host "📦 Output location: build/web/" -ForegroundColor Yellow
    
    # Optional: Serve locally for testing
    if (!$Release) {
        Write-Host "🌐 Starting local web server..." -ForegroundColor Blue
        Set-Location build/web
        python -m http.server 8000
    }
    
} catch {
    Write-Host "❌ Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### Android Configuration

#### Gradle Configuration (android/app/build.gradle)
```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterRoot = localProperties.getProperty('flutter.sdk')
if (flutterRoot == null) {
    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

// Get dart-define values
def dartEnvironmentVariables = [:]
if (project.hasProperty('dart-defines')) {
    project.property('dart-defines')
        .split(',')
        .each { item ->
            def keyValue = new String(item.decodeBase64(), 'UTF-8').split('=')
            dartEnvironmentVariables[keyValue[0]] = keyValue[1]
        }
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

// Firebase
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'

android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.revision"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // Dart-define variables
        dartEnvironmentVariables.each { key, value ->
            buildConfigField "String", key, "\"$value\""
            resValue "string", key, value
        }
    }

    flavorDimensions "default"
    productFlavors {
        dev {
            dimension "default"
            applicationId "com.example.revision.dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Revision Dev"
        }
        staging {
            dimension "default"
            applicationId "com.example.revision.staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "Revision Staging"
        }
        production {
            dimension "default"
            applicationId "com.example.revision"
            resValue "string", "app_name", "Revision"
        }
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Enable R8 full mode
            optimization {
                optimizeNonLiteralStrings false
            }
        }
        debug {
            signingConfig signingConfigs.debug
            minifyEnabled false
            debuggable true
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.7.4')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-crashlytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-storage'
    implementation 'com.google.firebase:firebase-functions'
    
    // Play Services
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

#### ProGuard Configuration (android/app/proguard-rules.pro)
```pro
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Your app's models
-keep class com.example.revision.** { *; }
```

### iOS Configuration

#### iOS Info.plist Configuration
```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>$(DISPLAY_NAME)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>revision</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    
    <!-- Camera and Photo Library permissions -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs access to camera to take photos for editing.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs access to photo library to select images for editing.</string>
    
    <!-- Firebase URL schemes -->
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>REVERSED_CLIENT_ID</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>$(REVERSED_CLIENT_ID)</string>
            </array>
        </dict>
    </array>
    
    <!-- App Transport Security -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>firebase.googleapis.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
```

## 🤖 CI/CD Pipeline Configuration

### GitHub Actions Workflows

#### Main CI/CD Pipeline
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

env:
  FLUTTER_VERSION: '3.24.0'
  JAVA_VERSION: '17'
  NODE_VERSION: '18'

jobs:
  analyze:
    name: Analyze & Test
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: ☕ Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: ${{ env.JAVA_VERSION }}
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        cache: true
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 🔍 Verify Flutter Installation
      run: flutter doctor -v
    
    - name: 🧹 Format Check
      run: dart format --output=none --set-exit-if-changed .
    
    - name: 🔍 Analyze Code
      run: flutter analyze
    
    - name: 🧪 Run Unit Tests
      run: flutter test --coverage --test-randomize-ordering-seed random
    
    - name: 📊 Upload Coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
        fail_ci_if_error: true
    
    - name: 📋 Coverage Report
      run: |
        sudo apt-get update
        sudo apt-get install -y lcov
        genhtml coverage/lcov.info --output-directory coverage/html
        echo "Coverage report generated at coverage/html/index.html"

  build-android:
    name: Build Android
    needs: analyze
    runs-on: ubuntu-latest
    timeout-minutes: 45
    
    strategy:
      matrix:
        environment: [development, staging, production]
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: ☕ Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: ${{ env.JAVA_VERSION }}
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        cache: true
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 🔐 Setup Keystore
      if: matrix.environment == 'production'
      run: |
        echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks
        echo "storeFile=upload-keystore.jks" >> android/key.properties
        echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
        echo "storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}" >> android/key.properties
        echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
    
    - name: 🏗️ Build Android APK
      run: |
        flutter build apk \
          --target=lib/main_${{ matrix.environment }}.dart \
          --flavor=${{ matrix.environment }} \
          --release \
          --dart-define=ENVIRONMENT=${{ matrix.environment }} \
          --dart-define=GEMINI_API_KEY_DEV=${{ secrets.GEMINI_API_KEY_DEV }} \
          --dart-define=GEMINI_API_KEY_STAGING=${{ secrets.GEMINI_API_KEY_STAGING }} \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 🏗️ Build Android App Bundle
      if: matrix.environment == 'production'
      run: |
        flutter build appbundle \
          --target=lib/main_${{ matrix.environment }}.dart \
          --flavor=${{ matrix.environment }} \
          --release \
          --dart-define=ENVIRONMENT=${{ matrix.environment }} \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 📦 Upload APK Artifact
      uses: actions/upload-artifact@v3
      with:
        name: revision-${{ matrix.environment }}-apk
        path: build/app/outputs/flutter-apk/*.apk
    
    - name: 📦 Upload App Bundle Artifact
      if: matrix.environment == 'production'
      uses: actions/upload-artifact@v3
      with:
        name: revision-production-aab
        path: build/app/outputs/bundle/productionRelease/*.aab

  build-ios:
    name: Build iOS
    needs: analyze
    runs-on: macos-latest
    timeout-minutes: 60
    
    strategy:
      matrix:
        environment: [development, staging, production]
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        cache: true
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 📦 Get iOS Dependencies
      run: cd ios && pod install
    
    - name: 🏗️ Build iOS (No Code Signing)
      run: |
        flutter build ios \
          --target=lib/main_${{ matrix.environment }}.dart \
          --release \
          --no-codesign \
          --dart-define=ENVIRONMENT=${{ matrix.environment }} \
          --dart-define=GEMINI_API_KEY_DEV=${{ secrets.GEMINI_API_KEY_DEV }} \
          --dart-define=GEMINI_API_KEY_STAGING=${{ secrets.GEMINI_API_KEY_STAGING }} \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 📦 Upload iOS Build Artifact
      uses: actions/upload-artifact@v3
      with:
        name: revision-${{ matrix.environment }}-ios
        path: build/ios/iphoneos/Runner.app

  build-web:
    name: Build Web
    needs: analyze
    runs-on: ubuntu-latest
    timeout-minutes: 30
    
    strategy:
      matrix:
        environment: [development, staging, production]
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: 'stable'
        cache: true
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 🌐 Build Web
      run: |
        flutter build web \
          --target=lib/main_${{ matrix.environment }}.dart \
          --release \
          --web-renderer=canvaskit \
          --dart-define=ENVIRONMENT=${{ matrix.environment }} \
          --dart-define=GEMINI_API_KEY_DEV=${{ secrets.GEMINI_API_KEY_DEV }} \
          --dart-define=GEMINI_API_KEY_STAGING=${{ secrets.GEMINI_API_KEY_STAGING }} \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 📦 Upload Web Build Artifact
      uses: actions/upload-artifact@v3
      with:
        name: revision-${{ matrix.environment }}-web
        path: build/web/

  deploy-web:
    name: Deploy Web
    needs: [build-web]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop')
    
    strategy:
      matrix:
        include:
          - environment: development
            branch: develop
            firebase_project: revision-464202-dev
          - environment: staging
            branch: develop
            firebase_project: revision-464202-staging
          - environment: production
            branch: main
            firebase_project: revision-464202
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 📦 Download Web Build
      uses: actions/download-artifact@v3
      with:
        name: revision-${{ matrix.environment }}-web
        path: build/web
    
    - name: 🔥 Setup Firebase CLI
      uses: w9jds/firebase-action@master
      with:
        args: deploy --only hosting --project ${{ matrix.firebase_project }}
      env:
        FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

  deploy-android:
    name: Deploy Android to Play Store
    needs: [build-android]
    runs-on: ubuntu-latest
    if: github.event_name == 'release' && github.event.action == 'published'
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 📦 Download App Bundle
      uses: actions/download-artifact@v3
      with:
        name: revision-production-aab
        path: build/app/outputs/bundle/productionRelease/
    
    - name: 🚀 Deploy to Play Store
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
        packageName: com.example.revision
        releaseFiles: build/app/outputs/bundle/productionRelease/*.aab
        track: internal
        status: completed
        inAppUpdatePriority: 2
```

#### Development Workflow
```yaml
# .github/workflows/development.yml
name: Development Workflow

on:
  push:
    branches: [ develop ]
  pull_request:
    branches: [ develop ]

jobs:
  test-and-deploy:
    name: Test & Deploy to Development
    runs-on: ubuntu-latest
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 🧪 Run Tests
      run: flutter test
    
    - name: 🏗️ Build Web for Development
      run: |
        flutter build web \
          --target=lib/main_development.dart \
          --release \
          --dart-define=ENVIRONMENT=development \
          --dart-define=GEMINI_API_KEY_DEV=${{ secrets.GEMINI_API_KEY_DEV }}
    
    - name: 🚀 Deploy to Firebase Hosting (Development)
      uses: w9jds/firebase-action@master
      with:
        args: deploy --only hosting --project revision-464202-dev
      env:
        FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
    
    - name: 💬 Comment PR with Preview Link
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        script: |
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: '🚀 Development build deployed! Preview: https://revision-464202-dev.web.app'
          })
```

## 🚀 Deployment Strategies

### Firebase Hosting Configuration
```json
// firebase.json
{
  "hosting": [
    {
      "target": "development",
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ],
      "headers": [
        {
          "source": "**/*.@(eot|otf|ttf|ttc|woff|font.css)",
          "headers": [
            {
              "key": "Access-Control-Allow-Origin",
              "value": "*"
            }
          ]
        },
        {
          "source": "**/*.@(js|css)",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "max-age=604800"
            }
          ]
        },
        {
          "source": "**/*.@(png|jpg|jpeg|gif|ico|svg|webp)",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "max-age=2592000"
            }
          ]
        }
      ]
    },
    {
      "target": "staging",
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "target": "production",
      "public": "build/web",
      "ignore": [
        "firebase.json",
        "**/.*",
        "**/node_modules/**"
      ],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ],
  "functions": {
    "source": "functions",
    "runtime": "nodejs18",
    "predeploy": [
      "npm --prefix \"$RESOURCE_DIR\" run lint",
      "npm --prefix \"$RESOURCE_DIR\" run build"
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "functions": {
      "port": 5001
    },
    "firestore": {
      "port": 8080
    },
    "hosting": {
      "port": 5000
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

### Google Play Store Configuration
```yaml
# .github/workflows/deploy-android-production.yml
name: Deploy Android to Production

on:
  release:
    types: [published]

jobs:
  deploy:
    name: Deploy to Google Play Store
    runs-on: ubuntu-latest
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: ☕ Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 🔐 Setup Keystore
      run: |
        echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks
        echo "storeFile=upload-keystore.jks" >> android/key.properties
        echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
        echo "storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}" >> android/key.properties
        echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
    
    - name: 🏗️ Build App Bundle
      run: |
        flutter build appbundle \
          --target=lib/main_production.dart \
          --flavor=production \
          --release \
          --dart-define=ENVIRONMENT=production \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 🚀 Upload to Google Play Store
      uses: r0adkll/upload-google-play@v1
      with:
        serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
        packageName: com.example.revision
        releaseFiles: build/app/outputs/bundle/productionRelease/*.aab
        track: production
        status: completed
        inAppUpdatePriority: 2
        changesNotSentForReview: false
        whatsNewDirectory: distribution/whatsnew
```

### App Store Connect Configuration
```yaml
# .github/workflows/deploy-ios-production.yml
name: Deploy iOS to App Store

on:
  release:
    types: [published]

jobs:
  deploy:
    name: Deploy to App Store Connect
    runs-on: macos-latest
    
    steps:
    - name: 📚 Checkout Repository
      uses: actions/checkout@v4
    
    - name: 🐦 Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
        channel: 'stable'
    
    - name: 📦 Get Dependencies
      run: flutter pub get
    
    - name: 📦 Get iOS Dependencies
      run: cd ios && pod install
    
    - name: 🔐 Import Code-Signing Certificates
      uses: Apple-Actions/import-codesign-certs@v2
      with:
        p12-file-base64: ${{ secrets.IOS_DISTRIBUTION_CERTIFICATE_BASE64 }}
        p12-password: ${{ secrets.IOS_DISTRIBUTION_CERTIFICATE_PASSWORD }}
    
    - name: 🔐 Download Provisioning Profiles
      uses: Apple-Actions/download-provisioning-profiles@v1
      with:
        bundle-id: com.example.revision
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
    
    - name: 🏗️ Build iOS App
      run: |
        flutter build ios \
          --target=lib/main_production.dart \
          --release \
          --dart-define=ENVIRONMENT=production \
          --dart-define=GEMINI_API_KEY_PROD=${{ secrets.GEMINI_API_KEY_PROD }}
    
    - name: 📦 Build and Archive
      run: |
        cd ios
        xcodebuild -workspace Runner.xcworkspace \
          -scheme Runner \
          -configuration Release \
          -destination generic/platform=iOS \
          -archivePath $PWD/build/Runner.xcarchive \
          archive
    
    - name: 🚀 Upload to App Store Connect
      run: |
        cd ios
        xcodebuild -exportArchive \
          -archivePath $PWD/build/Runner.xcarchive \
          -exportOptionsPlist $PWD/ExportOptions.plist \
          -exportPath $PWD/build
        
        xcrun altool --upload-app \
          --type ios \
          --file "$PWD/build/Runner.ipa" \
          --username "${{ secrets.APPSTORE_USERNAME }}" \
          --password "${{ secrets.APPSTORE_PASSWORD }}" \
          --verbose
```

## 📊 Monitoring & Analytics

### Performance Monitoring Setup
```dart
// lib/core/monitoring/performance_monitor.dart
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class PerformanceMonitor {
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  static Future<void> initialize() async {
    // Set custom keys for better crash reporting
    await _crashlytics.setCustomKey('environment', EnvConfig.environmentName);
    await _crashlytics.setCustomKey('app_version', '1.0.0');
    
    // Enable performance monitoring
    await _performance.setPerformanceCollectionEnabled(
      EnvConfig.enablePerformanceMonitoring,
    );
  }
  
  static Trace createTrace(String name) {
    return _performance.newTrace(name);
  }
  
  static HttpMetric createHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
  
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
  }) async {
    // Add custom keys if provided
    if (customKeys != null) {
      for (final entry in customKeys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    }
    
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }
  
  static Future<void> log(String message) async {
    await _crashlytics.log(message);
  }
}
```

### Build Optimization

#### Android Optimization
```gradle
// android/app/build.gradle optimization
android {
    buildTypes {
        release {
            // Enable R8 optimization
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Bundle optimization
            bundle {
                language {
                    enableSplit = true
                }
                density {
                    enableSplit = true
                }
                abi {
                    enableSplit = true
                }
            }
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
}
```

#### iOS Optimization
```ruby
# ios/Podfile optimization
platform :ios, '12.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Optimization: Enable bitcode
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

This comprehensive build and deployment guide ensures that your Revision Flutter application can be reliably built, tested, and deployed across all platforms with proper environment management and CI/CD automation.
