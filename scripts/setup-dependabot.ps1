
# Run this script to verify and initialize Dependabot for the repository

Write-Host "🤖 Setting up GitHub Dependabot for Flutter project..." -ForegroundColor Cyan
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in a Git repository" -ForegroundColor Red
    Write-Host "Please run this script from the root of your Git repository" -ForegroundColor Yellow
    exit 1
}

# Check if GitHub remote exists
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    Write-Host "⚠️  Warning: No GitHub remote found" -ForegroundColor Yellow
    Write-Host "Dependabot requires a GitHub repository to function" -ForegroundColor Yellow
}
else {
    Write-Host "✅ GitHub remote found: $remoteUrl" -ForegroundColor Green
}

# Check if Dependabot config exists
if (Test-Path ".github/dependabot.yml") {
    Write-Host "✅ Dependabot configuration exists" -ForegroundColor Green
}
else {
    Write-Host "❌ Dependabot configuration missing" -ForegroundColor Red
    Write-Host "The dependabot.yml file should be created in .github/ directory" -ForegroundColor Yellow
}

# Check if auto-merge workflow exists
if (Test-Path ".github/workflows/dependabot-auto-merge.yml") {
    Write-Host "✅ Dependabot auto-merge workflow exists" -ForegroundColor Green
}
else {
    Write-Host "❌ Dependabot auto-merge workflow missing" -ForegroundColor Red
}

# Check if security audit workflow exists
if (Test-Path ".github/workflows/security-audit.yml") {
    Write-Host "✅ Security audit workflow exists" -ForegroundColor Green
}
else {
    Write-Host "❌ Security audit workflow missing" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔧 Dependabot Configuration Summary:" -ForegroundColor Cyan
Write-Host "────────────────────────────────────" -ForegroundColor Gray

# Check and display Dependabot config summary
if (Test-Path ".github/dependabot.yml") {
    $content = Get-Content ".github/dependabot.yml" -Raw
    
    if ($content -match "pub") {
        Write-Host "📦 Flutter/Dart dependencies: Weekly schedule + Manual triggers" -ForegroundColor Green
    }
    if ($content -match "gradle") {
        Write-Host "🤖 Android Gradle: Weekly schedule + Manual triggers" -ForegroundColor Green
    }
    
    if ($content -match "github-actions") {
        Write-Host "⚡ GitHub Actions: Weekly schedule + Manual triggers" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Push these changes to your GitHub repository" -ForegroundColor White
Write-Host "2. Use 'Trigger Dependabot Manually' VS Code task for immediate updates" -ForegroundColor White
Write-Host "3. Configure branch protection rules if desired" -ForegroundColor White
Write-Host "4. Set up GitHub secrets if needed for auto-merge" -ForegroundColor White

Write-Host ""
Write-Host "🚀 To enable Dependabot on GitHub:" -ForegroundColor Cyan
Write-Host "   → Go to: Repository Settings > Security > Code security and analysis" -ForegroundColor White
Write-Host "   → Enable: Dependabot alerts, Dependabot security updates" -ForegroundColor White
Write-Host "   → Dependabot version updates will auto-enable with the config file" -ForegroundColor White

Write-Host ""
Write-Host "📚 Useful Commands:" -ForegroundColor Cyan
Write-Host "   gh pr list --author dependabot[bot]  # List Dependabot PRs" -ForegroundColor White
Write-Host "   flutter pub outdated                 # Check outdated packages" -ForegroundColor White
Write-Host "   flutter pub upgrade                  # Update all packages" -ForegroundColor White

Write-Host ""
Write-Host "✨ Dependabot setup verification complete!" -ForegroundColor Green
