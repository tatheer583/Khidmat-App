# Render the existing Android vector K mark as opaque iOS icon assets.
# Run on Windows with PowerShell; no font or image download is needed.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$iconRoot = Join-Path $repoRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$catalog = Get-Content -LiteralPath (Join-Path $iconRoot 'Contents.json') -Raw | ConvertFrom-Json
$vertices = @(@(29,25),@(42,25),@(42,49),@(65,25),@(82,25),@(54,54),
  @(83,83),@(65,83),@(42,59),@(42,83),@(29,83))
foreach ($entry in ($catalog.images | Sort-Object filename -Unique)) {
  $size = [int]([double]($entry.size -split 'x')[0] * [double]($entry.scale -replace 'x',''))
  $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#1A0A05'))
  try {
    $graphics.Clear([Drawing.ColorTranslator]::FromHtml('#E06A4A'))
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $points = [Drawing.PointF[]]@($vertices | ForEach-Object {
      [Drawing.PointF]::new([single]($_[0] * $size / 108), [single]($_[1] * $size / 108))
    })
    $graphics.FillPolygon($brush, $points)
    $bitmap.Save((Join-Path $iconRoot $entry.filename), [Drawing.Imaging.ImageFormat]::Png)
  } finally { $brush.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }
}
Write-Output 'iOS icons now use the Khidmat vector mark.'
