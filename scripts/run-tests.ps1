# Quick Test Runner Script
# Optimized for VGV Firebase Testing Strategy

Write-Host "🚀 VGV Firebase Test Runner" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Parse arguments
param(
    [switch]$Fast,
    [switch]$Integration, 
    [switch]$Coverage,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
VGV Firebase Test Runner

Usage: .\run-tests.ps1 [options]

Options:
  -Fast         Run only fast unit tests (10-15s)
  -Integration  Run integration tests with emulators  
  -Coverage     Generate coverage report
  -Help         Show this help

Examples:
  .\run-tests.ps1 -Fast         # Quick feedback loop
  .\run-tests.ps1 -Integration  # Full validation
  .\run-tests.ps1 -Coverage     # Complete analysis
"@
    exit 0
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    if ($Fast) {
        Write-Host "⚡ Running fast unit tests..." -ForegroundColor Yellow
        flutter test test/core/ test/features/*/domain/entities/ test/features/*/domain/exceptions/ --no-pub
    }
    elseif ($Integration) {
        Write-Host "🔥 Running integration tests..." -ForegroundColor Yellow
        # Start emulators if not running
        $emulatorRunning = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*firebase*emulator*" }
        if (-not $emulatorRunning) {
            Write-Host "   Starting Firebase emulators..." -ForegroundColor Gray
            Start-Process -FilePath "firebase" -ArgumentList "emulators:start", "--only=auth" -WindowStyle Hidden
            Start-Sleep -Seconds 10
        }
        
        flutter test test/integration/ --no-pub
    }
    elseif ($Coverage) {
        Write-Host "📊 Running tests with coverage..." -ForegroundColor Yellow
        flutter test --coverage --no-pub
        if (Test-Path "coverage/lcov.info") {
            Write-Host "✅ Coverage report generated: coverage/lcov.info" -ForegroundColor Green
        }
    }
    else {
        # Default: Run fast unit tests
        Write-Host "🎯 Running optimized test suite..." -ForegroundColor Yellow
        Write-Host "   Phase 1: Fast unit tests..." -ForegroundColor Gray
        flutter test test/core/ test/features/*/domain/entities/ test/features/*/domain/exceptions/ --concurrency=6 --no-pub
        
        Write-Host "   Phase 2: Presentation layer..." -ForegroundColor Gray  
        flutter test test/features/*/presentation/blocs/authentication_bloc_test.dart test/features/*/presentation/blocs/login_bloc_test.dart --no-pub
    }
    
    # Update: Add logic to find and use the correct .apk output path for install/deploy
    # Use the most recent debug .apk from build/app/outputs/flutter-apk/
    $apkPath = Get-ChildItem -Path "build/app/outputs/flutter-apk/" -Filter "*.apk" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $apkPath) {
        Write-Host "No APK found in build/app/outputs/flutter-apk/!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Using APK: $apkPath" -ForegroundColor Green
    # Example install command (uncomment if needed):
    # adb install -r $apkPath
    
    $stopwatch.Stop()
    $duration = $stopwatch.Elapsed
    
    Write-Host ""
    Write-Host "✅ Tests completed successfully!" -ForegroundColor Green
    Write-Host "⏱️  Total time: $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Cyan
    
}
catch {
    $stopwatch.Stop()
    Write-Host ""
    Write-Host "❌ Tests failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "⏱️  Failed after: $($stopwatch.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Yellow
    exit 1
}
