param(
    [switch]$release = $true
)

Write-Host "Building Flutter ARM64 APK..." -ForegroundColor Cyan

if ($release) {
    flutter build apk --release --target-platform android-arm64 --split-per-abi
} else {
    flutter build apk --target-platform android-arm64 --split-per-abi
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed. Exiting." -ForegroundColor Red
    exit $LASTEXITCODE
}

$appName = "Quest"
$targetDir = "build\app\outputs\flutter-apk"

Write-Host "Build successful! Cleaning up old builds..." -ForegroundColor Cyan

# Delete previous custom APKs (Quest-*.apk)
$oldApks = Get-ChildItem -Path $targetDir -Filter "$appName-*.apk" -ErrorAction SilentlyContinue
foreach ($apk in $oldApks) {
    Remove-Item $apk.FullName -Force
    Write-Host "Deleted old build: $($apk.Name)" -ForegroundColor DarkGray
}

# Generate a random 4-digit number
$randomNumber = Get-Random -Minimum 1000 -Maximum 9999

# The generated files are named app-arm64-v8a-release.apk, etc.
$generatedApks = Get-ChildItem -Path $targetDir -Filter "app-*.apk" -ErrorAction SilentlyContinue

if ($generatedApks.Count -gt 0) {
    Write-Host "`n=======================================================" -ForegroundColor Green
    Write-Host "SUCCESS: ARM64 APK renamed and ready!" -ForegroundColor Green

    foreach ($apk in $generatedApks) {
        $newName = $apk.Name -replace '^app-', "$appName-"
        $newName = $newName -replace '\.apk$', "-$randomNumber.apk"
        
        $newApkPath = "$targetDir\$newName"
        
        Copy-Item -Path $apk.FullName -Destination $newApkPath
        Write-Host "Location: $newApkPath" -ForegroundColor White
    }
    
    Write-Host "=======================================================" -ForegroundColor Green

} else {
    Write-Host "Could not find any APKs. Make sure the build succeeded." -ForegroundColor Red
}
