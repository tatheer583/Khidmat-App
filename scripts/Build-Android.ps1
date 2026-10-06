[CmdletBinding()]
param(
  [string]$ConfigFile = 'config/supabase.json',
  [switch]$AppBundle
)
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
  & $flutterPath --no-version-check analyze --no-fatal-infos
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
  & $flutterPath --no-version-check test
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
  $arguments = @('build', $(if ($AppBundle) { 'appbundle' } else { 'apk' }), '--release')
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
    Write-Output 'Building with first-launch Supabase connection setup.'
  }
  & $flutterPath --no-version-check @arguments
  if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
  $relativeArtifact = if ($AppBundle) { 'build/app/outputs/bundle/release/app-release.aab' }
    else { 'build/app/outputs/flutter-apk/app-release.apk' }
  $releaseRoot = Join-Path $repoRoot 'release'
  [IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
  $destination = Join-Path $releaseRoot $(if ($AppBundle) { 'khidmat-live.aab' } else { 'khidmat-live.apk' })
  Copy-Item -LiteralPath (Join-Path $repoRoot $relativeArtifact) -Destination $destination -Force
  Get-FileHash -LiteralPath $destination -Algorithm SHA256
  Write-Output ('Built: ' + $destination)
} finally { Pop-Location }
