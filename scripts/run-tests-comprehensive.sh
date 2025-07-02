#!/bin/bash

# Comprehensive test runner for Revision project
# This script ensures all tests run with proper environment setup

set -e

echo "🧪 Starting Revision Test Suite"
echo "==============================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter not found in PATH"
    exit 1
fi

# Create test environment file if it doesn't exist
if [ ! -f ".env.test" ]; then
    echo "📄 Creating .env.test file..."
    cat > .env.test << EOF
ENVIRONMENT=test
FIREBASE_PROJECT_ID=test-project
GEMINI_API_KEY=test-gemini-key
FIREBASE_WEB_API_KEY=test-web-api-key
FIREBASE_WEB_APP_ID=test-app-id
FIREBASE_WEB_MESSAGING_SENDER_ID=test-sender-id
FIREBASE_WEB_AUTH_DOMAIN=test-project.firebaseapp.com
FIREBASE_WEB_STORAGE_BUCKET=test-project.appspot.com
EOF
fi

# Copy test environment file for tests
cp .env.test .env

echo "🔧 Setting up test environment..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate code if needed
echo "🔨 Generating code..."
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Run dart analyze
echo "🔍 Running static analysis..."
flutter analyze

# Run tests with coverage
echo "🧪 Running tests with coverage..."
flutter test --coverage --reporter=expanded

# Check if coverage directory exists
if [ -d "coverage" ]; then
    echo "📊 Coverage report generated in coverage/ directory"
    
    # Generate HTML coverage report if lcov is available
    if command -v genhtml &> /dev/null; then
        echo "📈 Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        echo "📊 HTML coverage report available at coverage/html/index.html"
    fi
else
    echo "⚠️  No coverage directory found"
fi

# Restore original .env if it existed
if [ -f ".env.backup" ]; then
    mv .env.backup .env
else
    rm -f .env
fi

echo "✅ Test suite completed successfully!"
echo "==============================="
