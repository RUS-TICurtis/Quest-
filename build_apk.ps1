param(
    [switch]$release = $true
)

Write-Host "Building Flutter APK..." -ForegroundColor Cyan

if ($release) {
    flutter build apk --release
} else {
    flutter build apk
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed. Exiting." -ForegroundColor Red
    exit $LASTEXITCODE
}

$appName = "Quest"
$targetDir = "build\app\outputs\flutter-apk"
$originalApk = "$targetDir\app-release.apk"

if (Test-Path $originalApk) {
    Write-Host "Build successful! Cleaning up old builds..." -ForegroundColor Cyan
    
    # Delete previous custom APKs (Quest-*.apk)
    $oldApks = Get-ChildItem -Path $targetDir -Filter "$appName-*.apk" -ErrorAction SilentlyContinue
    foreach ($apk in $oldApks) {
        Remove-Item $apk.FullName -Force
        Write-Host "Deleted old build: $($apk.Name)" -ForegroundColor DarkGray
    }

    # Generate a random 4-digit number
    $randomNumber = Get-Random -Minimum 1000 -Maximum 9999
    $newApkName = "$appName-release-$randomNumber.apk"
    $newApkPath = "$targetDir\$newApkName"

    # Rename the newly built APK
    Rename-Item -Path $originalApk -NewName $newApkName
    
    Write-Host "`n=======================================================" -ForegroundColor Green
    Write-Host "SUCCESS: APK renamed and ready!" -ForegroundColor Green
    Write-Host "Location: $newApkPath" -ForegroundColor White
    Write-Host "=======================================================" -ForegroundColor Green

} else {
    Write-Host "Could not find the original $originalApk. Make sure the build succeeded." -ForegroundColor Red
}
