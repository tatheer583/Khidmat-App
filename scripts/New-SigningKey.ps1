[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$configRoot = Join-Path $repoRoot 'config'
$keystorePath = Join-Path $configRoot 'khidmat-upload.jks'
$passwordPath = Join-Path $configRoot 'signing-password.txt'
$propertiesPath = Join-Path $repoRoot 'android/key.properties'
if ((Test-Path -LiteralPath $keystorePath) -or (Test-Path -LiteralPath $propertiesPath)) {
  throw 'A signing key or signing configuration already exists. Keep it for app updates.'
}
if (!(Get-Command keytool -ErrorAction SilentlyContinue)) { throw 'Install Java 17+ first.' }
[IO.Directory]::CreateDirectory($configRoot) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $repoRoot 'android')) | Out-Null
$bytes = [byte[]]::new(32)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$password = [Convert]::ToBase64String($bytes)
[IO.File]::WriteAllText($passwordPath, $password, [Text.UTF8Encoding]::new($false))
$keyArguments = @('-genkeypair','-v','-keystore',$keystorePath,'-storetype','JKS',
  '-alias','khidmat','-storepass:file',$passwordPath,'-keypass:file',$passwordPath,
  '-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=Khidmat, O=Khidmat, C=PK')
& keytool @keyArguments
if ($LASTEXITCODE -ne 0) { throw 'Signing key creation failed.' }
$storePath = $keystorePath.Replace('\','/')
$properties = [string]::Join([Environment]::NewLine, @(
  "storePassword=$password","keyPassword=$password","keyAlias=khidmat","storeFile=$storePath",''))
[IO.File]::WriteAllText($propertiesPath, $properties, [Text.UTF8Encoding]::new($false))
Write-Output 'Signing key created. Back up config/khidmat-upload.jks, config/signing-password.txt and android/key.properties privately.'
