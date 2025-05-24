# This script must be run with admin privileges
# Right-click and choose "Run as administrator"

# Get the current PATH from the system environment
$currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)

# Check if Android SDK platform-tools is already at the beginning of the PATH
$androidSdkPath = "C:\Users\Sly\AppData\Local\Android\Sdk\platform-tools"
if ($currentPath.StartsWith($androidSdkPath)) {
    Write-Host "Android SDK platform-tools is already at the beginning of the PATH."
    exit
}

# Remove Android SDK platform-tools from PATH if it's already there
$pathEntries = $currentPath -split ";"
$pathEntries = $pathEntries | Where-Object { $_ -ne $androidSdkPath }

# Add Android SDK platform-tools to the beginning of PATH
$newPath = "$androidSdkPath;" + ($pathEntries -join ";")

# Update the system PATH
[Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)

Write-Host "PATH has been updated to prioritize Android SDK platform-tools."
Write-Host "Please restart any open terminals or applications for the changes to take effect."
