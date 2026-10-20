[CmdletBinding()]
param([switch]$AppBundle, [string]$ConfigurationFile = '')
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskTools = Join-Path $repoRoot '.tools'
if (Test-Path -LiteralPath $taskTools) {
  if (!$env:PUB_CACHE) { $env:PUB_CACHE = Join-Path $taskTools 'pub-cache' }
  if (!$env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME = Join-Path $taskTools 'gradle-cache' }
}
& (Join-Path $PSScriptRoot 'Prepare-Android.ps1')
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterPath = if ($flutterCommand) { $flutterCommand.Source } else { Join-Path $repoRoot '.tools/flutter/bin/flutter.bat' }
$localSdk = Join-Path $repoRoot '.tools/android-sdk'
if (Test-Path -LiteralPath $localSdk) {
  $env:ANDROID_HOME = $localSdk
  $env:ANDROID_SDK_ROOT = $localSdk
  & $flutterPath --no-version-check config --android-sdk $localSdk
  if ($LASTEXITCODE -ne 0) { throw 'Could not configure Android SDK.' }
}
Push-Location $repoRoot
try {
  & $flutterPath --no-version-check pub get
  if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
  & $flutterPath --no-version-check analyze --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
  & $flutterPath --no-version-check test --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
  if (!(Test-Path -LiteralPath (Join-Path $repoRoot 'android/key.properties'))) {
    throw 'Release signing is missing. Create the private signing key before distributing this build.'
  }
  $arguments = @('build', $(if ($AppBundle) { 'appbundle' } else { 'apk' }), '--release', '--no-pub')
  if ($ConfigurationFile) {
    $configurationPath = (Resolve-Path -LiteralPath $ConfigurationFile).Path
    $arguments += ('--dart-define-from-file=' + $configurationPath)
  }
  & $flutterPath --no-version-check @arguments
  if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
  $releaseRoot = Join-Path $repoRoot 'release'
  [IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
  if ($AppBundle) {
    $destination = Join-Path $releaseRoot 'khidmat.aab'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'build/app/outputs/bundle/release/app-release.aab') -Destination $destination -Force
  } else {
    $destination = Join-Path $releaseRoot 'khidmat-universal.apk'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk') -Destination $destination -Force
  }
  Get-FileHash -LiteralPath $destination -Algorithm SHA256
  Write-Output ('Built: ' + $destination)
} finally { Pop-Location }
