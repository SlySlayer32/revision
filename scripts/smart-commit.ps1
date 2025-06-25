#!/usr/bin/env pwsh

# Smart Commit Script - Handles Flutter analyze warnings gracefully
# Supports both strict (errors only) and permissive (info warnings OK) modes

param(
    [switch]$Force,
    [switch]$SkipAnalyze,
    [string]$Message,
    [string]$Type = "fix"
)

Write-Host "🚀 Smart Commit Tool" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Check if we have staged or unstaged changes
$status = git status --porcelain
if (-not $status) {
    Write-Host "❌ No changes to commit" -ForegroundColor Red
    exit 0
}

Write-Host "📋 Current changes:" -ForegroundColor Yellow
git status --short

# Get commit message if not provided
if (-not $Message) {
    Write-Host "`n📝 Commit Types:" -ForegroundColor Cyan
    Write-Host "1) feat: A new feature"
    Write-Host "2) fix: A bug fix" 
    Write-Host "3) docs: Documentation only changes"
    Write-Host "4) style: Changes that do not affect the meaning of the code"
    Write-Host "5) refactor: A code change that neither fixes a bug nor adds a feature"
    Write-Host "6) test: Adding missing tests or correcting existing tests"
    Write-Host "7) chore: Changes to the build process or auxiliary tools"
    
    $typeNum = Read-Host "`nEnter number (1-7) or press Enter for fix"
    
    $typeMap = @{
        "1" = "feat"
        "2" = "fix" 
        "3" = "docs"
        "4" = "style"
        "5" = "refactor"
        "6" = "test"
        "7" = "chore"
        ""  = "fix"
    }
    
    $Type = $typeMap[$typeNum]
    if (-not $Type) {
        Write-Host "❌ Invalid selection" -ForegroundColor Red
        exit 1
    }
    
    $Message = Read-Host "`nEnter commit message"
    if (-not $Message) {
        Write-Host "❌ Commit message is required" -ForegroundColor Red
        exit 1
    }
}

$commitMessage = "$Type`: $Message"

# Run Flutter analyze unless skipped
if (-not $SkipAnalyze) {
    Write-Host "`n🔍 Running Flutter analyze..." -ForegroundColor Yellow
    
    $analyzeResult = flutter analyze 2>&1
    $analyzeExitCode = $LASTEXITCODE
    
    if ($analyzeExitCode -eq 0) {
        Write-Host "✅ Flutter analyze passed!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  Flutter analyze found issues:" -ForegroundColor Yellow
        Write-Host $analyzeResult -ForegroundColor Gray
        
        # Count error vs info/warning levels
        $errors = ($analyzeResult -split "`n" | Where-Object { $_ -match "error -" }).Count
        $warnings = ($analyzeResult -split "`n" | Where-Object { $_ -match "warning -" }).Count  
        $infos = ($analyzeResult -split "`n" | Where-Object { $_ -match "info -" }).Count
        
        Write-Host "`n📊 Issue Summary:" -ForegroundColor Cyan
        Write-Host "   Errors: $errors" -ForegroundColor Red
        Write-Host "   Warnings: $warnings" -ForegroundColor Yellow
        Write-Host "   Info: $infos" -ForegroundColor Blue
        
        if ($errors -gt 0 -and -not $Force) {
            Write-Host "`n❌ Found $errors errors. Fix them or use -Force to commit anyway." -ForegroundColor Red
            exit 1
        }
        
        if (($warnings -gt 0 -or $infos -gt 0) -and -not $Force) {
            $continue = Read-Host "`n⚠️  Found $warnings warnings and $infos info issues. Continue? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                Write-Host "❌ Commit cancelled" -ForegroundColor Red
                exit 1
            }
        }
    }
}

# Stage all changes
Write-Host "`n📦 Staging changes..." -ForegroundColor Yellow
git add .

# Create commit
Write-Host "💾 Creating commit..." -ForegroundColor Yellow
try {
    if ($Force) {
        git commit --no-verify -m $commitMessage
    }
    else {
        git commit -m $commitMessage
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Commit created successfully!" -ForegroundColor Green
        Write-Host "   Message: $commitMessage" -ForegroundColor Cyan
        
        # Ask about pushing
        $push = Read-Host "`n🚀 Push to remote? (Y/n)"
        if ($push -ne "n" -and $push -ne "N") {
            Write-Host "📤 Pushing to remote..." -ForegroundColor Yellow
            git push
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Successfully pushed to remote!" -ForegroundColor Green
            }
            else {
                Write-Host "⚠️  Push failed, but commit was successful" -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "❌ Commit failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Error during commit: $_" -ForegroundColor Red
    exit 1
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

Write-Host "`n🎉 All done!" -ForegroundColor Green
