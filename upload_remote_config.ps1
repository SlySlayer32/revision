# Simple Firebase Remote Config Upload Script
# Uploads the template using Firebase CLI to get access token and curl for REST API

$ProjectId = "revision-464202"
$TemplateFile = "firebase_remote_config_template.json"

Write-Host "🔧 Uploading Firebase Remote Config..." -ForegroundColor Cyan

# Check if template exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "❌ Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

# Get Firebase access token
Write-Host "🔑 Getting Firebase access token..." -ForegroundColor Yellow
try {
    $accessToken = firebase auth:print-tokens --json | ConvertFrom-Json | Select-Object -ExpandProperty access_token
    Write-Host "✅ Access token obtained" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to get access token. Please run 'firebase login'" -ForegroundColor Red
    exit 1
}

# Read template content
$templateContent = Get-Content $TemplateFile -Raw

# Upload using REST API
$url = "https://firebaseremoteconfig.googleapis.com/v1/projects/$ProjectId/remoteConfig"
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

Write-Host "🚀 Uploading template to Firebase..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $templateContent
    Write-Host "✅ Remote Config uploaded successfully!" -ForegroundColor Green
    Write-Host "Version: $($response.version.versionNumber)" -ForegroundColor White
}
catch {
    Write-Host "❌ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Success! Your Remote Config has been updated." -ForegroundColor Green
Write-Host "View in Console: https://console.firebase.google.com/project/$ProjectId/config" -ForegroundColor Blue
