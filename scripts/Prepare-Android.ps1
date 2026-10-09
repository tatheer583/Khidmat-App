[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (!$flutterCommand) {
  $localFlutter = Join-Path $repoRoot '.tools/flutter/bin/flutter.bat'
  if (Test-Path -LiteralPath $localFlutter) { $flutterCommand = Get-Item -LiteralPath $localFlutter }
  else { throw 'Flutter is missing. Run scripts/Install-Toolchain.ps1 first or install Flutter 3.38.1+.' }
}
$flutterPath = $flutterCommand.Source
if (!$flutterPath) { $flutterPath = $flutterCommand.FullName }
$wrapper = Join-Path $repoRoot 'android/gradlew'
if (!(Test-Path -LiteralPath $wrapper)) {
  # Generate native scaffolding separately so Flutter never overwrites our app code.
  $templateRoot = Join-Path $repoRoot ('.build-tools/android-' + [guid]::NewGuid().ToString('N'))
  & $flutterPath --no-version-check create --no-pub --platforms=android --org=com.khidmat --project-name=khidmat $templateRoot
  if ($LASTEXITCODE -ne 0) { throw 'Flutter could not generate the Android project.' }
  $generatedAndroid = Join-Path $templateRoot 'android'
  $androidRoot = Join-Path $repoRoot 'android'
  [IO.Directory]::CreateDirectory($androidRoot) | Out-Null
  # Remove only obsolete Groovy build files when replacing legacy scaffolding.
  foreach ($relative in @('build.gradle','settings.gradle','app/build.gradle')) {
    $generatedKotlin = Join-Path $generatedAndroid ($relative + '.kts')
    $legacyFile = Join-Path $androidRoot $relative
    if ((Test-Path -LiteralPath $generatedKotlin) -and (Test-Path -LiteralPath $legacyFile)) {
      Remove-Item -LiteralPath $legacyFile
    }
  }
  # Only fill missing scaffolding; keep our manifest, icons and Gradle settings.
  foreach ($file in (Get-ChildItem -LiteralPath $generatedAndroid -File -Recurse)) {
    $relative = [IO.Path]::GetRelativePath($generatedAndroid, $file.FullName)
    $destination = Join-Path $androidRoot $relative
    if (!(Test-Path -LiteralPath $destination)) {
      [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
      Copy-Item -LiteralPath $file.FullName -Destination $destination
    }
  }
}
$manifestPath = Join-Path $repoRoot 'android/app/src/main/AndroidManifest.xml'
$manifest = [IO.File]::ReadAllText($manifestPath)
$manifest = $manifest.Replace('android:label="khidmat"', 'android:label="Khidmat"')
$manifest = $manifest.Replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@drawable/khidmat_icon"')
[IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))

$gradlePath = Join-Path $repoRoot 'android/app/build.gradle.kts'
if (!(Test-Path -LiteralPath $gradlePath)) { throw 'Expected Flutter 3.35+ Kotlin Gradle scaffolding.' }
$gradle = [IO.File]::ReadAllText($gradlePath)
if (!$gradle.Contains('khidmatKeyProperties')) {
  $header = @'
import java.util.Properties

val khidmatKeyProperties = Properties()
val khidmatKeyFile = rootProject.file("key.properties")
if (khidmatKeyFile.exists()) {
    khidmatKeyFile.inputStream().use { khidmatKeyProperties.load(it) }
}

'@
  $signing = @'
android {
    signingConfigs {
        if (khidmatKeyFile.exists()) {
            create("khidmatRelease") {
                keyAlias = khidmatKeyProperties.getProperty("keyAlias")
                keyPassword = khidmatKeyProperties.getProperty("keyPassword")
                storeFile = file(khidmatKeyProperties.getProperty("storeFile"))
                storePassword = khidmatKeyProperties.getProperty("storePassword")
            }
        }
    }
'@
  # Keep the generated plugin block first; Kotlin Gradle requires plugins before values.
  $gradle = $gradle.Replace('android {', $header + $signing)
  $gradle = 'import java.util.Properties' + [Environment]::NewLine +
    [regex]::Replace($gradle, '(?m)^import java\.util\.Properties\r?\n', '')
  $gradle = $gradle.Replace('signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = if (khidmatKeyFile.exists()) signingConfigs.getByName("khidmatRelease") else signingConfigs.getByName("debug")')
  [IO.File]::WriteAllText($gradlePath, $gradle, [Text.UTF8Encoding]::new($false))
}
# Kotlin incremental caches cannot relativize plugin sources across Windows drives.
$propertiesFile = Join-Path $repoRoot 'android/gradle.properties'
if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
  $properties = [IO.File]::ReadAllText($propertiesFile)
  if (!$properties.Contains('kotlin.incremental=false')) {
    $properties += [Environment]::NewLine + 'kotlin.incremental=false' +
      [Environment]::NewLine + 'kotlin.compiler.execution.strategy=in-process' + [Environment]::NewLine
    [IO.File]::WriteAllText($propertiesFile, $properties, [Text.UTF8Encoding]::new($false))
  }
}
Write-Output 'Android project prepared.'
