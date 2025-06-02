# Launch Aider with Virtual Environment
Write-Host ">> Activating virtual environment and launching Aider..." -ForegroundColor Cyan

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

Write-Host ">> Virtual environment activated" -ForegroundColor Green
Write-Host ">> Available packages: aider, google-generativeai" -ForegroundColor Blue
Write-Host ""

# Load API key from .env file
Write-Host ">> Loading API key from .env file..." -ForegroundColor Yellow
if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match 'GOOGLE_API_KEY="([^"]*)"') {
        $env:GOOGLE_API_KEY = $matches[1]
        Write-Host ">> Google API key loaded successfully!" -ForegroundColor Green
    } else {
        Write-Host ">> Could not find GOOGLE_API_KEY in .env file" -ForegroundColor Red
    }
} else {
    Write-Host ">> .env file not found" -ForegroundColor Red
}

Write-Host ""
Write-Host ">> Starting Aider with Gemini support..." -ForegroundColor Cyan

# Launch Aider with Gemini model
aider --model gemini/gemini-1.5-pro
