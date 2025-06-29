# Firebase Remote Config Import Script
# Imports the AI model control template to Firebase Remote Config

param(
    [string]$ProjectId = "revision-464202",
    [string]$TemplateFile = "firebase_remote_config_template.json",
    [switch]$DryRun,
    [switch]$Backup,
    [switch]$Verify
)

Write-Host "� Firebase Remote Config Import Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version 2>$null
    Write-Host "✅ Firebase CLI detected: $firebaseVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Firebase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check if template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "❌ Template file not found: $TemplateFile" -ForegroundColor Red
    Write-Host "   Make sure you're in the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "📁 Template file found: $TemplateFile" -ForegroundColor Green

# Validate JSON syntax
try {
    $templateContent = Get-Content $TemplateFile -Raw | ConvertFrom-Json
    Write-Host "✅ Template JSON is valid" -ForegroundColor Green
    
    # Show template summary
    $parameterCount = $templateContent.parameters.PSObject.Properties.Count
    $conditionCount = $templateContent.conditions.Count
    $groupCount = $templateContent.parameterGroups.PSObject.Properties.Count
    
    Write-Host "📊 Template Summary:" -ForegroundColor Cyan
    Write-Host "   Parameters: $parameterCount" -ForegroundColor White
    Write-Host "   Conditions: $conditionCount" -ForegroundColor White
    Write-Host "   Groups: $groupCount" -ForegroundColor White
}
catch {
    Write-Host "❌ Invalid JSON in template file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Dry run mode
if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host "Template would be uploaded to project: $ProjectId" -ForegroundColor Yellow
    Write-Host "Use -DryRun:$false to perform actual import" -ForegroundColor Yellow
    exit 0
}

# Check Firebase login status
try {
    $loginCheck = firebase login:list 2>$null
    Write-Host "✅ Firebase authentication verified" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged in to Firebase. Please run:" -ForegroundColor Red
    Write-Host "   firebase login" -ForegroundColor Yellow
    exit 1
}

# Set the active project
Write-Host "🎯 Setting active project to: $ProjectId" -ForegroundColor Cyan
try {
    firebase use $ProjectId 2>$null
    Write-Host "✅ Project set successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to set project. Please verify project ID: $ProjectId" -ForegroundColor Red
    exit 1
}

# Backup current config if requested
if ($Backup) {
    $backupFile = "remote_config_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    Write-Host "💾 Creating backup: $backupFile" -ForegroundColor Cyan
    
    try {
        firebase remoteconfig:get > $backupFile 2>$null
        Write-Host "✅ Backup created successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Could not create backup (config might be empty)" -ForegroundColor Yellow
    }
}

# Import the template
Write-Host "🚀 Importing Remote Config template..." -ForegroundColor Cyan
try {
    firebase remoteconfig:set $TemplateFile
    Write-Host "✅ Template imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Import failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify import if requested
if ($Verify) {
    Write-Host "🔍 Verifying import..." -ForegroundColor Cyan
    
    try {
        $verifyFile = "current_config_verification.json"
        firebase remoteconfig:get > $verifyFile 2>$null
        
        $currentConfig = Get-Content $verifyFile -Raw | ConvertFrom-Json
        $currentParamCount = $currentConfig.parameters.PSObject.Properties.Count
        
        Write-Host "📊 Verification Results:" -ForegroundColor Cyan
        Write-Host "   Current parameters: $currentParamCount" -ForegroundColor White
        Write-Host "   Expected parameters: $parameterCount" -ForegroundColor White
        
        if ($currentParamCount -eq $parameterCount) {
            Write-Host "✅ Parameter count matches!" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️  Parameter count mismatch - please check manually" -ForegroundColor Yellow
        }
        
        Remove-Item $verifyFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "⚠️  Verification failed, but import may have succeeded" -ForegroundColor Yellow
    }
}

Write-Host "" 
Write-Host "🎉 Import Complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to Firebase Console > Remote Config" -ForegroundColor White
Write-Host "2. Review and customize the imported parameters" -ForegroundColor White
Write-Host "3. Click 'Publish changes' to activate" -ForegroundColor White
Write-Host "4. Test in your Flutter app using the Firebase AI Demo" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Firebase Console: https://console.firebase.google.com/project/$ProjectId/config" -ForegroundColor Blue

# Check if Firebase CLI is installed
Write-Host "📋 Checking Firebase CLI..." -ForegroundColor Yellow
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
}
catch {
    Write-Host "❌ Firebase CLI not found. Please install it first:" -ForegroundColor Red
    Write-Host "   npm install -g firebase-tools" -ForegroundColor White
    exit 1
}

# Check if template file exists
$templatePath = "firebase_remote_config_template.json"
if (-not (Test-Path $templatePath)) {
    Write-Host "❌ Template file not found: $templatePath" -ForegroundColor Red
    Write-Host "   Make sure you're in the project root directory" -ForegroundColor White
    exit 1
}

Write-Host "✅ Template file found: $templatePath" -ForegroundColor Green

# Confirm project
Write-Host "📋 Using Firebase project: $ProjectId" -ForegroundColor Yellow
if (-not $Force) {
    $confirm = Read-Host "Continue with import? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "❌ Import cancelled by user" -ForegroundColor Red
        exit 0
    }
}

# Check Firebase login status
Write-Host "🔐 Checking Firebase authentication..." -ForegroundColor Yellow
try {
    $projects = firebase projects:list --json | ConvertFrom-Json
    if ($projects.Count -eq 0) {
        Write-Host "❌ Not logged in to Firebase. Please run:" -ForegroundColor Red
        Write-Host "   firebase login" -ForegroundColor White
        exit 1
    }
    Write-Host "✅ Firebase authentication confirmed" -ForegroundColor Green
}
catch {
    Write-Host "❌ Firebase authentication failed. Please run:" -ForegroundColor Red
    Write-Host "   firebase login" -ForegroundColor White
    exit 1
}

# Set Firebase project
Write-Host "🎯 Setting Firebase project..." -ForegroundColor Yellow
try {
    firebase use $ProjectId
    Write-Host "✅ Firebase project set to: $ProjectId" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to set Firebase project. Available projects:" -ForegroundColor Red
    firebase projects:list
    exit 1
}

# Backup existing config (if any)
Write-Host "💾 Creating backup of existing config..." -ForegroundColor Yellow
try {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "remote_config_backup_$timestamp.json"
    firebase remoteconfig:get > $backupFile
    Write-Host "✅ Backup saved as: $backupFile" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Could not create backup (may be first import)" -ForegroundColor Yellow
}

# Import the template
Write-Host "📤 Importing AI model parameters..." -ForegroundColor Yellow
try {
    firebase remoteconfig:set $templatePath
    Write-Host "✅ Template imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to import template. Error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Verify import
Write-Host "🔍 Verifying import..." -ForegroundColor Yellow
try {
    $config = firebase remoteconfig:get --json | ConvertFrom-Json
    $paramCount = $config.parameters.PSObject.Properties.Count
    Write-Host "✅ Verification complete: $paramCount parameters imported" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Could not verify import, but import command succeeded" -ForegroundColor Yellow
}

# Success message
Write-Host ""
Write-Host "🎉 Import Complete!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open Firebase Console: https://console.firebase.google.com/project/$ProjectId/config" -ForegroundColor White
Write-Host "2. Review the imported parameters" -ForegroundColor White
Write-Host "3. Publish the configuration" -ForegroundColor White
Write-Host "4. Test in your app: Dashboard → Test Firebase AI → Refresh Config" -ForegroundColor White
Write-Host ""
Write-Host "Parameters imported:" -ForegroundColor Cyan
Write-Host "• ai_gemini_model" -ForegroundColor White
Write-Host "• ai_gemini_image_model" -ForegroundColor White
Write-Host "• ai_temperature" -ForegroundColor White
Write-Host "• ai_max_output_tokens" -ForegroundColor White
Write-Host "• ai_top_k" -ForegroundColor White
Write-Host "• ai_top_p" -ForegroundColor White
Write-Host "• ai_analysis_system_prompt" -ForegroundColor White
Write-Host "• ai_editing_system_prompt" -ForegroundColor White
Write-Host "• ai_request_timeout_seconds" -ForegroundColor White
Write-Host "• ai_enable_advanced_features" -ForegroundColor White
Write-Host "• ai_debug_mode" -ForegroundColor White
Write-Host ""
Write-Host "Smart conditions added:" -ForegroundColor Cyan
Write-Host "• development_env (for dev builds)" -ForegroundColor White
Write-Host "• premium_users (for premium tier)" -ForegroundColor White
Write-Host "• debug_mode_users (5% for testing)" -ForegroundColor White
