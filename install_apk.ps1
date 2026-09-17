$appName = "Quest"
$targetDir = "build\app\outputs\flutter-apk"

Write-Host "Looking for existing $appName APKs..." -ForegroundColor Cyan

$existingApks = Get-ChildItem -Path $targetDir -Filter "$appName-*.apk" -ErrorAction SilentlyContinue

if ($existingApks.Count -eq 0) {
    Write-Host "No APKs found in $targetDir." -ForegroundColor Red
    Write-Host "Run .\build_apk_arm64.ps1 or .\build_apk_split_abi.ps1 first." -ForegroundColor Yellow
    exit 1
}

foreach ($apk in $existingApks) {
    Write-Host "`nInstalling $($apk.Name) to connected device..." -ForegroundColor Cyan
    if (Get-Command adb -ErrorAction SilentlyContinue) {
        adb install -r $apk.FullName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully installed $($apk.Name)!" -ForegroundColor Green
        } else {
            Write-Host "Failed to install $($apk.Name). Make sure a device is connected and unlocked." -ForegroundColor Red
        }
    } else {
        Write-Host "ERROR: 'adb' is not recognized. Please add Android SDK platform-tools to your system PATH." -ForegroundColor Red
    }
}
