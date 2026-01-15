$ErrorActionPreference = "Stop"

$sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$emulatorExe = Join-Path $sdkRoot "emulator\emulator.exe"
$adbExe = Join-Path $sdkRoot "platform-tools\adb.exe"

if (-not (Test-Path $emulatorExe)) {
    Write-Error "Android emulator was not found at '$emulatorExe'. Install the Android SDK emulator from Android Studio."
}

if (-not (Test-Path $adbExe)) {
    Write-Error "adb was not found at '$adbExe'. Install Android platform-tools from Android Studio."
}

$avdList = @(& $emulatorExe -list-avds)

if (-not $avdList -or $avdList.Count -eq 0) {
    Write-Host "No Android Virtual Device exists yet."
    Write-Host "Create one in Android Studio > More Actions > Virtual Device Manager, then run this script again."
    exit 1
}

$selectedAvd = if ($Args.Count -gt 0) { $Args[0] } else { $avdList[0] }

if ($selectedAvd -notin $avdList) {
    Write-Error "AVD '$selectedAvd' was not found. Available AVDs: $($avdList -join ', ')"
}

Write-Host "Starting emulator '$selectedAvd'..."
Start-Process -FilePath $emulatorExe -ArgumentList "-avd `"$selectedAvd`""

Write-Host "Waiting for device to connect..."
& $adbExe wait-for-device | Out-Null
Write-Host "Emulator is available."
