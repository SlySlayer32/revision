# Git Workflow Automation

This project includes an automated Git workflow system to help maintain consistent version control and provide safety nets when developing features.

## Commands

After importing the PowerShell module, you can use these commands:

### 1. Start a New Feature
```powershell
New-Feature -FeatureName "feature-name"
```
This will:
- Create/switch to development branch
- Create and switch to a new feature branch
- Set up tracking with remote

### 2. Save Changes (With Backup)
```powershell
Save-Changes -Message "your commit message"
```
This will:
- Create a backup branch with timestamp
- Commit changes to both working and backup branches
- Push both branches to remote

### 3. Merge Feature to Development
```powershell
Merge-Feature -FeatureBranch "feature/feature-name"
```
This will:
- Switch to development branch
- Merge the feature branch
- Push changes to remote

### 4. Create Production Release
```powershell
Start-Production
```
This will:
- Merge development into master
- Create a tagged release
- Push changes and tags to remote

## Best Practices

1. Always start new features using `New-Feature`
2. Commit frequently using `Save-Changes`
3. Create meaningful commit messages
4. Test thoroughly before merging to development
5. Only use `Start-Production` when ready for release

## Recovery

If you need to recover from a backup:
1. List backup branches: `git branch -r | Select-String "backup/"`
2. Choose the relevant backup
3. Create a new branch from the backup: `git checkout -b recovery/feature-name backup/branch-name`
