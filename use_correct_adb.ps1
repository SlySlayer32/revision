# Kill any existing ADB servers
& "C:\Users\Sly\AppData\Local\Android\Sdk\platform-tools\adb.exe" kill-server

# Start a new ADB server
& "C:\Users\Sly\AppData\Local\Android\Sdk\platform-tools\adb.exe" start-server

Write-Host "ADB server restarted with the correct version from Android SDK"
Write-Host "Connected devices:"
& "C:\Users\Sly\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
