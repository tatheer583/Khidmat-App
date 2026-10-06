#requires -Version 7
[CmdletBinding()]
param([string]$ConfigFile = 'config/app.public.json')
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
$headers = @{apikey=$config.SUPABASE_ANON_KEY}
$auth = Invoke-RestMethod -Uri ($config.SUPABASE_URL + '/auth/v1/settings') -Headers $headers -TimeoutSec 20
$health = Invoke-WebRequest -Uri ($config.SUPABASE_URL + '/rest/v1/rpc/app_health') -Headers $headers -Method Post -ContentType 'application/json' -Body '{}' -TimeoutSec 20 -SkipHttpErrorCheck
$installed = $health.StatusCode -eq 200 -and ($health.Content | ConvertFrom-Json).ready -eq $true
[pscustomobject]@{
  DatabaseStorageRealtimeReady = $installed
  EmailEnabled = $auth.external.email
  PhoneEnabled = $auth.external.phone
}
if (!$installed) { Write-Output 'Apply the missing migrations in docs/ACTIVATE-SUPABASE.md, then run this check again.'; exit 1 }
if (!$auth.external.phone) { Write-Output 'Phone OTP needs an enabled SMS provider. Email sign-in remains available.' }
