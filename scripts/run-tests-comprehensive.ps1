# Comprehensive test runner for Revision project (PowerShell)
# This script ensures all tests run with proper environment setup

$ErrorActionPreference = "Stop"

Write-Host "🧪 Starting Revision Test Suite" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check if Flutter is available
try {
    flutter --version | Out-Null
} catch {
    Write-Host "❌ Error: Flutter not found in PATH" -ForegroundColor Red
    exit 1
}

# Create test environment file if it doesn't exist
if (-not (Test-Path ".env.test")) {
    Write-Host "📄 Creating .env.test file..." -ForegroundColor Yellow
    @"
ENVIRONMENT=test
FIREBASE_PROJECT_ID=test-project
GEMINI_API_KEY=test-gemini-key
FIREBASE_WEB_API_KEY=test-web-api-key
FIREBASE_WEB_APP_ID=test-app-id
FIREBASE_WEB_MESSAGING_SENDER_ID=test-sender-id
FIREBASE_WEB_AUTH_DOMAIN=test-project.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=test-project.appspot.com
"@ | Out-File -FilePath ".env.test" -Encoding UTF8
}

# Backup original .env if it exists
if (Test-Path ".env") {
    Copy-Item ".env" ".env.backup" -Force
}

# Copy test environment file for tests
Copy-Item ".env.test" ".env" -Force

Write-Host "🔧 Setting up test environment..." -ForegroundColor Yellow

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Generate code if needed
Write-Host "🔨 Generating code..." -ForegroundColor Yellow
if ((Test-Path "pubspec.yaml") -and ((Get-Content "pubspec.yaml") -like "*build_runner*")) {
    flutter packages pub run build_runner build --delete-conflicting-outputs
}

# Run dart analyze
Write-Host "🔍 Running static analysis..." -ForegroundColor Yellow
flutter analyze

# Run tests with coverage
Write-Host "🧪 Running tests with coverage..." -ForegroundColor Yellow
flutter test --coverage --reporter=expanded

# Check if coverage directory exists
if (Test-Path "coverage") {
    Write-Host "📊 Coverage report generated in coverage/ directory" -ForegroundColor Green
} else {
    Write-Host "⚠️  No coverage directory found" -ForegroundColor Yellow
}

# Restore original .env if it existed
if (Test-Path ".env.backup") {
    Move-Item ".env.backup" ".env" -Force
} else {
    Remove-Item ".env" -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ Test suite completed successfully!" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Cyan
