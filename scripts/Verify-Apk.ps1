[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Apk,
  [string]$SdkRoot = 'A:\Khidmat-Tools\android-sdk',
  [int]$ExpectedVersionCode = 5003
)
$ErrorActionPreference = 'Stop'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
$buildTools = Get-ChildItem -LiteralPath (Join-Path $SdkRoot 'build-tools') -Directory |
  Sort-Object Name -Descending | Select-Object -First 1
if (!$buildTools) { throw 'Android build tools were not found.' }
$signature = & (Join-Path $buildTools.FullName 'apksigner.bat') verify --verbose --print-certs $apkPath
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
$expectedSigner = '7c680b76c6d8ba235ebc72b68b05038ecaddb0d38e7d776f977695db2cdacebd'
if (($signature -join ' ') -notmatch $expectedSigner) { throw 'Unexpected release signing certificate.' }
& (Join-Path $buildTools.FullName 'zipalign.exe') -c -P 16 4 $apkPath
if ($LASTEXITCODE -ne 0) { throw 'APK native library alignment failed.' }
$badging = & (Join-Path $buildTools.FullName 'aapt2.exe') dump badging $apkPath
if ($LASTEXITCODE -ne 0) { throw 'Android package could not be parsed.' }
if (($badging -join ' ') -notmatch ("name='com.khidmat.khidmat' versionCode='" + $ExpectedVersionCode + "'")) {
  throw 'Unexpected package ID or version code.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($apkPath)
try {
  $entries = $archive.Entries.FullName
  foreach ($required in @('AndroidManifest.xml','classes.dex','resources.arsc','assets/flutter_assets/AssetManifest.bin')) {
    if ($entries -notcontains $required) { throw ('Incomplete APK: missing ' + $required) }
  }
  $appLibraries = @($entries | Where-Object { $_ -match '^lib/[^/]+/libapp\.so$' })
  if ($appLibraries.Count -eq 0) { throw 'No compiled Dart application in APK.' }
  foreach ($app in $appLibraries) {
    if ($entries -notcontains $app.Replace('libapp.so','libflutter.so')) { throw 'Flutter engine missing for an ABI.' }
  }
} finally { $archive.Dispose() }
$hash = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
[pscustomobject]@{
  file = [IO.Path]::GetFileName($apkPath)
  bytes = (Get-Item -LiteralPath $apkPath).Length
  sha256 = $hash
  versionCode = $ExpectedVersionCode
  signerSha256 = $expectedSigner
  nativeLibraries = $appLibraries
  signatureVerified = $true
  alignment16KBVerified = $true
}
