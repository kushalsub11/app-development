$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidStudioJbr = "C:\Program Files\Android\Android Studio\jbr"
$gradleBat = Join-Path $projectRoot "android\gradlew.bat"

if (-not (Test-Path (Join-Path $androidStudioJbr "bin\java.exe"))) {
    Write-Error "JDK not found at '$androidStudioJbr'. Install Android Studio or update android-build.ps1."
}

if (-not (Test-Path $gradleBat)) {
    Write-Error "Gradle wrapper not found at '$gradleBat'."
}

$env:JAVA_HOME = $androidStudioJbr
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

Set-Location (Join-Path $projectRoot "android")

if ($Args.Count -eq 0) {
    & $gradleBat assembleDebug
} else {
    & $gradleBat @Args
}
