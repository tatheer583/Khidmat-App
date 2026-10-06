[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$stagingRoot = Join-Path $repoRoot ('.build-tools/package-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($stagingRoot) | Out-Null
# Explicit allowlist keeps SDKs, backend connection settings and signing secrets out.
foreach ($relative in @('lib','android','ios','scripts','supabase','test','docs','.github',
  'pubspec.yaml','analysis_options.yaml','.gitignore','README.md')) {
  $source = Join-Path $repoRoot $relative
  if (Test-Path -LiteralPath $source -PathType Container) {
    foreach ($file in (Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object {
      $_.FullName -notmatch '[/\\](node_modules|\.temp|\.branches|\.gradle|\.kotlin|build|\.cxx|Pods|\.symlinks|ephemeral)[/\\]' -and
      $_.Name -notmatch '^(key\.properties|local\.properties|Generated\.xcconfig|flutter_export_environment\.sh)$' -and $_.Extension -ne '.jks'
    })) {
      $fileRelative = [IO.Path]::GetRelativePath($repoRoot, $file.FullName)
      $target = Join-Path $stagingRoot $fileRelative
      [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
      Copy-Item -LiteralPath $file.FullName -Destination $target
    }
  } else {
    Copy-Item -LiteralPath $source -Destination (Join-Path $stagingRoot $relative)
  }
}
foreach ($relative in @('pubspec.lock')) {
  $source = Join-Path $repoRoot $relative
  if (Test-Path -LiteralPath $source) {
    Copy-Item -LiteralPath $source -Destination (Join-Path $stagingRoot $relative)
  }
}
foreach ($relative in @('config/supabase.example.json','config/app.public.json',
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/res/drawable/khidmat_icon.xml')) {
  $target = Join-Path $stagingRoot $relative
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
  Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $target
}
# Supabase CLI generates local state if somebody runs it before packaging.
$localState = Join-Path $stagingRoot 'supabase/.temp'
if (Test-Path -LiteralPath $localState) {
  $resolvedState = [IO.Path]::GetFullPath($localState)
  if (!$resolvedState.StartsWith($stagingRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package cleanup path.' }
  Remove-Item -LiteralPath $resolvedState -Recurse -Force
}
$releaseRoot = Join-Path $repoRoot 'release'
[IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
$destination = Join-Path $releaseRoot 'Khidmat-Supabase-source.zip'
Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $destination -Force
# Verify contents without exposing private files.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($destination)
try {
  $entries = $archive.Entries.FullName
  if ($entries | Where-Object {$_ -match '(?i)(\.jks$|key\.properties$|signing-password|config[/\\]supabase\.json$)'}) {
    throw 'Source package contains private configuration.'
  }
  Write-Output ('Source archive verified: ' + $entries.Count + ' entries.')
} finally { $archive.Dispose() }
Write-Output $destination
