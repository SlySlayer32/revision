# Git Workflow Automation Script

function New-Feature {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FeatureName
    )
    
    # Create and switch to development branch if it doesn't exist
    $devBranch = git branch --list development
    if (-not $devBranch) {
        git checkout -b development
        git push -u origin development
    } else {
        git checkout development
        git pull origin development
    }

    # Create and switch to feature branch
    $branchName = "feature/$FeatureName"
    git checkout -b $branchName
    Write-Host "Created and switched to new feature branch: $branchName"
}

function Save-Changes {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    # Create backup branch with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $backupBranch = "backup/${currentBranch}_$timestamp"
    git checkout -b $backupBranch
    
    # Stage and commit changes in backup branch
    git add .
    git commit -m "Backup: $Message"
    git push origin $backupBranch
    
    # Return to original branch
    git checkout $currentBranch
    
    # Stage and commit changes in original branch
    git add .
    git commit -m $Message
    git push origin $currentBranch
    
    Write-Host "Changes saved in both working branch and backup branch: $backupBranch"
}

function Merge-Feature {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FeatureBranch
    )
    
    # Switch to development branch
    git checkout development
    git pull origin development
    
    # Merge feature branch
    git merge $FeatureBranch
    
    # Push changes
    git push origin development
    
    Write-Host "Merged $FeatureBranch into development"
}

function Start-Production {
    # Update development branch
    git checkout development
    git pull origin development
    
    # Update master branch
    git checkout master
    git pull origin master
    
    # Merge development into master
    git merge development
    
    # Create release tag with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    git tag -a "release_$timestamp" -m "Release $timestamp"
    
    # Push changes and tags
    git push origin master
    git push origin --tags
    
    Write-Host "Production release created and tagged: release_$timestamp"
}

# Export functions for PowerShell module usage
Export-ModuleMember -Function New-Feature, Save-Changes, Merge-Feature, Start-Production
