[CmdletBinding()]
param(
  [string]$ConfigFile = 'config/app.public.json',
  [switch]$AppBundle,
  [switch]$SplitPerAbi,
  [switch]$AllowUnconfigured
)
$ErrorActionPreference = 'Stop'
if ($AppBundle -and $SplitPerAbi) {
  throw 'Choose either -AppBundle or -SplitPerAbi.'
}
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
  & $flutterPath --no-version-check analyze --no-pub --no-fatal-infos
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
  & $flutterPath --no-version-check test --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
  $arguments = @('build', $(if ($AppBundle) { 'appbundle' } else { 'apk' }), '--release', '--no-pub')
  if (!(Test-Path -LiteralPath (Join-Path $repoRoot 'android/key.properties'))) {
    throw 'Release signing is missing. Create the private signing key before distributing this build.'
  }
  if (!(Test-Path -LiteralPath $ConfigFile -PathType Leaf) -and
      [IO.Path]::IsPathRooted($ConfigFile)) { throw 'Supabase config file does not exist.' }
  if (Test-Path -LiteralPath $ConfigFile -PathType Leaf) {
    $config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    if (!$config.SUPABASE_URL -or !$config.SUPABASE_ANON_KEY) { throw 'Supabase config is incomplete.' }
    $appKey = [string]$config.SUPABASE_ANON_KEY
    if (!$appKey.StartsWith('sb_publishable_')) {
      try {
        $payload = $appKey.Split('.')[1].Replace('-','+').Replace('_','/')
        $payload = $payload.PadRight($payload.Length + ((4 - $payload.Length % 4) % 4),'=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
        if ($claims.role -ne 'anon') { throw 'Invalid app key role' }
      } catch { throw 'Only a publishable or legacy anon key can be embedded in the APK.' }
  }
  $arguments += ('--dart-define-from-file=' + $ConfigFile)
  } else {
    if (!$AllowUnconfigured) { throw 'Missing Supabase configuration. Use -AllowUnconfigured only for an intentional setup build.' }
    Write-Output 'Building with first-launch Supabase connection setup.'
  }
  if ($SplitPerAbi) { $arguments += '--split-per-abi' }
  & $flutterPath --no-version-check @arguments
  if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
  $releaseRoot = Join-Path $repoRoot 'release'
  [IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
  if ($AppBundle) {
    $destination = Join-Path $releaseRoot 'khidmat-live.aab'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'build/app/outputs/bundle/release/app-release.aab') -Destination $destination -Force
    Get-FileHash -LiteralPath $destination -Algorithm SHA256
    Write-Output ('Built: ' + $destination)
  } elseif ($SplitPerAbi) {
    $abiArtifacts = @{
      'arm64-v8a' = 'app-arm64-v8a-release.apk'
      'armeabi-v7a' = 'app-armeabi-v7a-release.apk'
      'x86_64' = 'app-x86_64-release.apk'
    }
    foreach ($abi in $abiArtifacts.Keys) {
      $destination = Join-Path $releaseRoot ('khidmat-' + $abi + '.apk')
      Copy-Item -LiteralPath (Join-Path $repoRoot ('build/app/outputs/flutter-apk/' + $abiArtifacts[$abi])) -Destination $destination -Force
      Get-FileHash -LiteralPath $destination -Algorithm SHA256
      Write-Output ('Built: ' + $destination)
    }
    Write-Output 'Built APKs for each Android architecture. The universal APK is provided for one-download installs.'
  } else {
    $destination = Join-Path $releaseRoot 'khidmat-live.apk'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk') -Destination $destination -Force
    Get-FileHash -LiteralPath $destination -Algorithm SHA256
    Write-Output ('Built: ' + $destination)
  }
} finally { Pop-Location }
