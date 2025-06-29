#!/usr/bin/env powershell
# scripts/run-comprehensive-tests.ps1

# Comprehensive test runner for AI pipeline
# Following VGV Clean Architecture testing strategy

param(
    [string]$TestType = "all",
    [switch]$Coverage = $false,
    [switch]$Verbose = $false,
    [string]$Filter = ""
)

Write-Host "🧪 Starting Comprehensive AI Pipeline Tests..." -ForegroundColor Cyan
Write-Host "📅 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# Test configuration
$TestResults = @{
    Unit        = @{ Passed = 0; Failed = 0; Duration = 0 }
    Widget      = @{ Passed = 0; Failed = 0; Duration = 0 }
    Integration = @{ Passed = 0; Failed = 0; Duration = 0 }
    AI          = @{ Passed = 0; Failed = 0; Duration = 0 }
}

function Run-TestSuite {
    param(
        [string]$SuiteName,
        [string]$TestPath,
        [string]$Tags = "",
        [int]$TimeoutMinutes = 5
    )
    
    Write-Host "`n🔄 Running $SuiteName Tests..." -ForegroundColor Yellow
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $testArgs = @("test")
        
        if ($TestPath) {
            $testArgs += $TestPath
        }
        
        if ($Tags) {
            $testArgs += "--tags", $Tags
        }
        
        if ($Coverage -and $SuiteName -eq "Unit") {
            $testArgs += "--coverage"
        }
        
        if ($Verbose) {
            $testArgs += "--verbose"
        }
        
        if ($Filter) {
            $testArgs += "--name", $Filter
        }
        
        $testArgs += "--timeout", "${TimeoutMinutes}m"
        
        Write-Host "Command: flutter $($testArgs -join ' ')" -ForegroundColor Gray
        
        $result = & flutter @testArgs
        $exitCode = $LASTEXITCODE
        
        $stopwatch.Stop()
        $TestResults[$SuiteName].Duration = $stopwatch.ElapsedMilliseconds
        
        if ($exitCode -eq 0) {
            $TestResults[$SuiteName].Passed = 1
            Write-Host "PASS: $SuiteName Tests PASSED (${stopwatch.ElapsedMilliseconds}ms)" -ForegroundColor Green
            return $true
        }
        else {
            $TestResults[$SuiteName].Failed = 1
            Write-Host "FAIL: $SuiteName Tests FAILED (${stopwatch.ElapsedMilliseconds}ms)" -ForegroundColor Red
            if ($Verbose) {
                Write-Host $result -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        $stopwatch.Stop()
        $TestResults[$SuiteName].Failed = 1
        $TestResults[$SuiteName].Duration = $stopwatch.ElapsedMilliseconds
        Write-Host "ERROR: $SuiteName Tests CRASHED: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-TestSummary {
    Write-Host "`nSUMMARY: Test Results Summary" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Gray
    
    $totalPassed = 0
    $totalFailed = 0
    $totalDuration = 0
    
    foreach ($suite in $TestResults.Keys) {
        $result = $TestResults[$suite]
        $status = if ($result.Failed -gt 0) { "FAIL" } elseif ($result.Passed -gt 0) { "PASS" } else { "SKIP" }
        $duration = "{0:N0}ms" -f $result.Duration
        
        Write-Host "$suite Tests: $status ($duration)" -ForegroundColor $(if ($result.Failed -gt 0) { "Red" } elseif ($result.Passed -gt 0) { "Green" } else { "Yellow" })
        
        $totalPassed += $result.Passed
        $totalFailed += $result.Failed
        $totalDuration += $result.Duration
    }
    
    Write-Host "`nOverall: $totalPassed passed, $totalFailed failed" -ForegroundColor $(if ($totalFailed -gt 0) { "Red" } else { "Green" })
    Write-Host "Total Duration: {0:N0}ms ({1:N1}s)" -f $totalDuration, ($totalDuration / 1000) -ForegroundColor Gray
    
    if ($Coverage -and (Test-Path "coverage/lcov.info")) {
        Write-Host "`nCOVERAGE: Generating Coverage Report..." -ForegroundColor Cyan
        try {
            & genhtml coverage/lcov.info -o coverage/html --quiet 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "PASS: Coverage report generated: coverage/html/index.html" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "WARN: Could not generate HTML coverage report" -ForegroundColor Yellow
        }
    }
    
    return ($totalFailed -eq 0)
}

# Pre-test setup
Write-Host "`nSETUP: Pre-test Setup..." -ForegroundColor Yellow

# Ensure Flutter is available
try {
    $flutterVersion = & flutter --version --machine | ConvertFrom-Json
    Write-Host "PASS: Flutter version: $($flutterVersion.flutterVersion)" -ForegroundColor Green
}
catch {
    Write-Host "FAIL: Flutter not found or not working" -ForegroundColor Red
    exit 1
}

# Get dependencies
Write-Host "DEPS: Getting dependencies..."
& flutter pub get | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Failed to get dependencies" -ForegroundColor Red
    exit 1
}

$allTestsPassed = $true

# Run test suites based on TestType
switch ($TestType.ToLower()) {
    "unit" {
        $allTestsPassed = Run-TestSuite "Unit" "test/unit/" "unit" 3
    }
    "widget" {
        $allTestsPassed = Run-TestSuite "Widget" "test/widget/" "widget" 5
    }
    "integration" {
        $allTestsPassed = Run-TestSuite "Integration" "test/integration/" "integration" 10
    }
    "ai" {
        $allTestsPassed = Run-TestSuite "AI" "" "ai" 15
    }
    "core" {
        $passed1 = Run-TestSuite "Unit" "test/unit/core/" "unit" 3
        $passed2 = Run-TestSuite "AI" "test/unit/core/services/*ai*" "ai" 10
        $allTestsPassed = $passed1 -and $passed2
    }
    "all" {
        $passed1 = Run-TestSuite "Unit" "test/unit/" "unit" 5
        $passed2 = Run-TestSuite "Widget" "test/widget/" "widget" 8
        $passed3 = Run-TestSuite "Integration" "test/integration/" "integration" 15
        $passed4 = Run-TestSuite "AI" "" "ai" 20
        $allTestsPassed = $passed1 -and $passed2 -and $passed3 -and $passed4
    }
    default {
        Write-Host "FAIL: Unknown test type: $TestType" -ForegroundColor Red
        Write-Host "Valid types: unit, widget, integration, ai, core, all" -ForegroundColor Yellow
        exit 1
    }
}

# Show summary
$success = Show-TestSummary

# Additional checks for AI pipeline
if ($TestType -eq "all" -or $TestType -eq "ai") {
    Write-Host "`nAI: AI Pipeline Verification..." -ForegroundColor Cyan
    
    # Check AI configuration
    if (Test-Path "lib/core/config/ai_config.dart") {
        Write-Host "PASS: AI Config found" -ForegroundColor Green
    }
    else {
        Write-Host "FAIL: AI Config missing" -ForegroundColor Red
        $success = $false
    }
    
    # Check Firebase Remote Config template
    if (Test-Path "firebase/remoteconfig.template.json") {
        Write-Host "[PASS] Remote Config template found" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] Remote Config template missing" -ForegroundColor Red
        $success = $false
    }
    
    # Check AI service implementations
    $aiServices = @(
        "lib/core/services/gemini_ai_service.dart",
        "lib/core/services/gemini_pipeline_service.dart",
        "lib/features/ai_processing/infrastructure/services/ai_analysis_service.dart"
    )
    
    foreach ($service in $aiServices) {
        if (Test-Path $service) {
            Write-Host "[PASS] $(Split-Path $service -Leaf) found" -ForegroundColor Green
        }
        else {
            Write-Host "[FAIL] $(Split-Path $service -Leaf) missing" -ForegroundColor Red
            $success = $false
        }
    }
}

# Final result
Write-Host "`n" + "=" * 60 -ForegroundColor Gray
if ($success) {
    Write-Host "[SUCCESS] ALL TESTS PASSED! AI Pipeline is ready for production." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "[FAILED] TESTS FAILED! Please review and fix issues before deployment." -ForegroundColor Red
    exit 1
}
