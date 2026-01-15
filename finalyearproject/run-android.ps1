$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"

if (-not (Test-Path (Join-Path $androidStudioJbr "bin\java.exe"))) {
    Write-Error "JDK not found at '$androidStudioJbr'. Install Android Studio or update run-android.ps1."
}

$env:JAVA_HOME = $androidStudioJbr
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Set-Location $projectRoot

Write-Host "Using JAVA_HOME=$env:JAVA_HOME"
flutter run --no-track-widget-creation @Args
