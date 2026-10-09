[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$stagingRoot = Join-Path $repoRoot ('.build-tools/package-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($stagingRoot) | Out-Null
# Explicit source allowlist excludes SDKs, generated files and signing secrets.
foreach ($relative in @('lib','android','ios','scripts','test','docs','.github',
  'pubspec.yaml','pubspec.lock','analysis_options.yaml','.gitignore','README.md')) {
  $source = Join-Path $repoRoot $relative
  if (Test-Path -LiteralPath $source -PathType Container) {
    foreach ($file in (Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object {
      $_.FullName -notmatch '[/\\](node_modules|__pycache__|\.temp|\.branches|\.gradle|\.kotlin|build|\.cxx|Pods|\.symlinks|ephemeral)[/\\]' -and
      $_.Name -notmatch '^(key\.properties|local\.properties|Generated\.xcconfig|flutter_export_environment\.sh|GeneratedPluginRegistrant\.(java|h|m))$' -and $_.Extension -ne '.jks'
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
$releaseRoot = Join-Path $repoRoot 'release'
[IO.Directory]::CreateDirectory($releaseRoot) | Out-Null
$destination = Join-Path $releaseRoot 'Khidmat-source.zip'
Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $destination -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($destination)
try {
  $entries = $archive.Entries.FullName
  if ($entries | Where-Object {$_ -match '(?i)(\.jks$|key\.properties$|signing-password|supabase[/\\]|config[/\\])'}) {
    throw 'Source package contains obsolete backend or private configuration.'
  }
  Write-Output ('Source archive verified: ' + $entries.Count + ' entries.')
} finally { $archive.Dispose() }
$resolvedStaging = [IO.Path]::GetFullPath($stagingRoot)
if (!$resolvedStaging.StartsWith((Join-Path $repoRoot '.build-tools') + [IO.Path]::DirectorySeparatorChar,
  [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package cleanup path.' }
Remove-Item -LiteralPath $resolvedStaging -Recurse -Force
Write-Output $destination
