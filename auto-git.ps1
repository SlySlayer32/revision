$watchPath = $PSScriptRoot
$filter = "*.*"  # Watch all files
$autoCommitEnabled = $true

# Create a FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define what happens when a file changes
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Skip if change is in .git folder or build artifacts
    if ($path -like "*\.git\*" -or 
        $path -like "*\build\*" -or 
        $path -like "*\.dart_tool\*") {
        return
    }
    
    # Get relative path for commit message
    $relativePath = $path.Replace($watchPath, "").TrimStart("\")
    
    if ($autoCommitEnabled) {
        # Stage and commit the change
        Set-Location $watchPath
        git add $path
        git commit -m "Auto-commit: $changeType in $relativePath at $timeStamp"
        
        # Try to push (if there's a remote)
        try {
            git push
        } catch {
            Write-Host "Note: Changes committed locally but not pushed to remote"
        }
        
        Write-Host "Auto-committed: $changeType in $relativePath"
    }
}

# Register the event handlers
$handlers = . {
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action
}

Write-Host "Auto-Git is now watching for changes in $watchPath"
Write-Host "Press Ctrl+C to stop watching..."

try {
    # Keep the script running
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Clean up
    $handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    $watcher.Dispose()
    Write-Host "Stopped watching for changes"
}
