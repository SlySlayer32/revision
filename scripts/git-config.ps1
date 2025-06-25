# Git Automation Configuration
# This file centralizes all Git automation settings and can be sourced by other scripts

# Repository Information
$REPO_URL = "https://github.com/SlySlayer32/revision.git"
$DEFAULT_BRANCH = "development"
$UPSTREAM_BRANCH = "origin/development"

# Commit Configuration
$DEFAULT_COMMIT_MESSAGE = "feat: comprehensive object removal debugging and MVP enhancements

- Fixed image loading and preview logic in AiProcessingView
- Enhanced error handling and debug output throughout AI processing pipeline
- Implemented proper processed image display in ProcessingResultDisplay
- Added comprehensive logging for annotation conversion and marker creation
- Improved VertexAI service integration with better error handling
- Updated AI processing repository to include system instructions
- Enhanced Git automation and repository tracking

Resolves: Image object removal pipeline not loading/processing correctly
Implements: Robust debugging infrastructure and automation"

# File Patterns to Always Include (even if large)
$ALWAYS_INCLUDE_PATTERNS = @(
    "*.dart",
    "*.yaml", 
    "*.yml",
    "*.json",
    "*.md",
    "*.gitignore",
    "pubspec.*",
    "analysis_options.yaml",
    ".github/**",
    "scripts/**",
    "docs/**"
)

# File Patterns to Always Exclude
$ALWAYS_EXCLUDE_PATTERNS = @(
    "**/.cxx/**",
    "**/build/**",
    "**/.gradle/**",
    "**/.dart_tool/**",
    "**/node_modules/**",
    "**/*.log",
    "**/.idea/**",
    "**/Pods/**"
)

# Size Limits (in MB)
$MAX_FILE_SIZE_MB = 50
$MAX_TOTAL_SIZE_MB = 500

# Automation Behavior
$AUTO_ADD_ALL = $true
$AUTO_PUSH = $true
$CREATE_BACKUP_BRANCH = $true
$BACKUP_BRANCH_PREFIX = "backup-"
$REQUIRE_CONFIRMATION = $false

# Error Recovery
$MAX_RETRIES = 3
$RETRY_DELAY_SECONDS = 5

# Branch Strategy
$FEATURE_BRANCH_PREFIX = "feature/"
$BUGFIX_BRANCH_PREFIX = "bugfix/"
$HOTFIX_BRANCH_PREFIX = "hotfix/"

# Pre-commit Checks
$RUN_FLUTTER_ANALYZE = $true
$RUN_DART_FORMAT = $true
$CHECK_PUBSPEC_LOCK = $true

Write-Host "🔧 Git automation configuration loaded" -ForegroundColor Green
Write-Host "📍 Repository: $REPO_URL" -ForegroundColor Cyan
Write-Host "🌿 Default Branch: $DEFAULT_BRANCH" -ForegroundColor Cyan
Write-Host "📦 Max file size: ${MAX_FILE_SIZE_MB}MB" -ForegroundColor Cyan
