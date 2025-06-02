#!/usr/bin/env powershell

# Script to run tests with Firebase emulator setup
param(
    [string]$TestType = "unit",
    [switch]$Coverage,
    [switch]$EmulatorMode
)

Write-Host "🧪 Running tests with Firebase emulator configuration..." -ForegroundColor Cyan

# Start Firebase emulators if in emulator mode
if ($EmulatorMode) {
    Write-Host "🔥 Starting Firebase emulators..." -ForegroundColor Yellow
    Start-Job -ScriptBlock { firebase emulators:start --only auth,firestore } -Name "FirebaseEmulators"
    Start-Sleep -Seconds 5  # Wait for emulators to start
}

try {
    # Set environment variables for emulator mode
    $env:USE_AUTH_EMULATOR = "true"
    $env:USE_FIRESTORE_EMULATOR = "true"
    $env:FIREBASE_HOST = "10.0.2.2"
    $env:FIREBASE_AUTH_PORT = "9099"
    $env:FIREBASE_FIRESTORE_PORT = "8080"

    switch ($TestType) {
        "unit" {
            Write-Host "🧪 Running unit tests..." -ForegroundColor Green
            if ($Coverage) {
                flutter test --coverage
                genhtml coverage/lcov.info -o coverage/html
                Write-Host "📊 Coverage report generated in coverage/html/" -ForegroundColor Blue
            } else {
                flutter test
            }
        }
        "integration" {
            Write-Host "🧪 Running integration tests..." -ForegroundColor Green
            flutter test integration_test/
        }
        "auth" {
            Write-Host "🧪 Running authentication tests..." -ForegroundColor Green
            flutter test test/features/authentication/ --coverage
        }
        default {
            Write-Host "❌ Unknown test type: $TestType" -ForegroundColor Red
            Write-Host "Available types: unit, integration, auth" -ForegroundColor Yellow
            exit 1
        }
    }

    Write-Host "✅ Tests completed successfully!" -ForegroundColor Green

} catch {
    Write-Host "❌ Tests failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up Firebase emulators if they were started
    if ($EmulatorMode) {
        Write-Host "🛑 Stopping Firebase emulators..." -ForegroundColor Yellow
        Stop-Job -Name "FirebaseEmulators" -ErrorAction SilentlyContinue
        Remove-Job -Name "FirebaseEmulators" -ErrorAction SilentlyContinue
    }
}
