[CmdletBinding()]
param(
  [switch]$CheckDownloadsOnly,
  [string]$ToolsRoot = '',
  [switch]$AcceptAndroidLicenses
)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$toolsRoot = if ($ToolsRoot) { [IO.Path]::GetFullPath($ToolsRoot) } else { Join-Path $repoRoot '.tools' }
$manifestUrl = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
Write-Output 'Checking official Flutter download metadata…'
$manifest = Invoke-RestMethod -Uri $manifestUrl -TimeoutSec 30
$release = $manifest.releases | Where-Object hash -eq $manifest.current_release.stable | Select-Object -First 1
if (!$release) { throw 'Could not identify the stable Flutter release.' }
$flutterUrl = $manifest.base_url.TrimEnd('/') + '/' + $release.archive
$androidUrl = 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip'
$androidSha = '90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a'
if ($CheckDownloadsOnly) {
  Invoke-WebRequest -Uri $androidUrl -Method Head -TimeoutSec 30 | Out-Null
  Write-Output ('Downloads reachable. Stable Flutter: ' + $release.version)
  return
}
if (!(Get-Command git -ErrorAction SilentlyContinue)) { throw 'Install Git for Windows first.' }
if (!(Get-Command java -ErrorAction SilentlyContinue)) { throw 'Install Java 17 or newer first.' }
[IO.Directory]::CreateDirectory($toolsRoot) | Out-Null
$flutterRoot = Join-Path $toolsRoot 'flutter'
if (!(Test-Path -LiteralPath (Join-Path $flutterRoot 'bin/flutter.bat'))) {
  $flutterArchive = Join-Path $toolsRoot 'flutter.zip'
  Write-Output ('Downloading Flutter ' + $release.version + ' (large download)…')
  Invoke-WebRequest -Uri $flutterUrl -OutFile $flutterArchive -TimeoutSec 3600
  if ($release.sha256 -and (Get-FileHash -LiteralPath $flutterArchive).Hash.ToLowerInvariant() -ne $release.sha256) {
    throw 'Flutter archive checksum does not match.'
  }
  Expand-Archive -LiteralPath $flutterArchive -DestinationPath $toolsRoot -Force
}
$sdkRoot = Join-Path $toolsRoot 'android-sdk'
$sdkManager = Join-Path $sdkRoot 'cmdline-tools/latest/bin/sdkmanager.bat'
if (!(Test-Path -LiteralPath $sdkManager)) {
  Write-Output 'Android SDK license: https://developer.android.com/studio#terms'
  if (!$AcceptAndroidLicenses) {
    $accept = Read-Host 'Read the Android SDK terms above. Type ACCEPT to download and install the SDK'
    if ($accept -cne 'ACCEPT') { throw 'Android SDK installation was cancelled.' }
  }
  $androidArchive = Join-Path $toolsRoot 'android-tools.zip'
  Invoke-WebRequest -Uri $androidUrl -OutFile $androidArchive -TimeoutSec 600
  if ((Get-FileHash -LiteralPath $androidArchive).Hash.ToLowerInvariant() -ne $androidSha) {
    throw 'Android command-line tools checksum does not match.'
  }
  $extractRoot = Join-Path $toolsRoot ('android-extract-' + [guid]::NewGuid().ToString('N'))
  Expand-Archive -LiteralPath $androidArchive -DestinationPath $extractRoot
  $cmdlineRoot = Join-Path $sdkRoot 'cmdline-tools'
  [IO.Directory]::CreateDirectory($cmdlineRoot) | Out-Null
  Copy-Item -LiteralPath (Join-Path $extractRoot 'cmdline-tools') -Destination (Join-Path $cmdlineRoot 'latest') -Recurse
}
$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$flutterPath = Join-Path $flutterRoot 'bin/flutter.bat'
if ($AcceptAndroidLicenses) { 1..100 | ForEach-Object { 'y' } | & $sdkManager "--sdk_root=$sdkRoot" --licenses }
else { & $sdkManager "--sdk_root=$sdkRoot" --licenses }
if ($LASTEXITCODE -ne 0) { throw 'Android licenses have not been accepted.' }
$extension = [IO.File]::ReadAllText((Join-Path $flutterRoot 'packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt'))
$match = [regex]::Match($extension,'compileSdkVersion\s*:\s*Int\s*=\s*(\d+)')
$api = if ($match.Success) { $match.Groups[1].Value } else { '36' }
& $sdkManager "--sdk_root=$sdkRoot" 'platform-tools' "platforms;android-$api" 'platforms;android-34' 'build-tools;36.0.0' 'ndk;28.2.13676358' 'cmake;3.22.1'
if ($LASTEXITCODE -ne 0) { throw 'Android SDK package installation failed.' }
& $flutterPath config --android-sdk $sdkRoot
if ($LASTEXITCODE -ne 0) { throw 'Flutter SDK configuration failed.' }
& $flutterPath doctor -v
Write-Output ('Toolchain installed at ' + $toolsRoot + '. Add flutter/bin to PATH or link .tools here, then run scripts/Build-Android.ps1.')
