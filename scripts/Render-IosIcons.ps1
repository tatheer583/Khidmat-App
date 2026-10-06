# Render the Khidmat home-service mark as opaque iOS icon assets.
# Run on Windows with PowerShell; no font or image download is needed.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$iconRoot = Join-Path $repoRoot 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
$catalog = Get-Content -LiteralPath (Join-Path $iconRoot 'Contents.json') -Raw | ConvertFrom-Json
function Draw-KhidmatMark($graphics, [single]$x, [single]$y, [single]$markSize,
    [bool]$roundedBackground = $true) {
  $scale = [single]($markSize / 108)
  $tile = [Drawing.RectangleF]::new($x, $y, $markSize, $markSize)
  $tilePath = [Drawing.Drawing2D.GraphicsPath]::new()
  $radius = [single]($markSize * .24)
  $diameter = $radius * 2
  $tilePath.AddArc($tile.X, $tile.Y, $diameter, $diameter, 180, 90)
  $tilePath.AddArc($tile.Right-$diameter, $tile.Y, $diameter, $diameter, 270, 90)
  $tilePath.AddArc($tile.Right-$diameter, $tile.Bottom-$diameter, $diameter, $diameter, 0, 90)
  $tilePath.AddArc($tile.X, $tile.Bottom-$diameter, $diameter, $diameter, 90, 90)
  $tilePath.CloseFigure()
  $accent = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#E06A4A'))
  $ink = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#1A0A05'))
  $cream = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#FFF4EE'))
  try {
    if ($roundedBackground) { $graphics.FillPath($accent, $tilePath) }
    else { $graphics.FillRectangle($accent, $tile) }
    $points = [Drawing.PointF[]]@(
      [Drawing.PointF]::new($x+14*$scale,$y+49*$scale), [Drawing.PointF]::new($x+54*$scale,$y+17*$scale),
      [Drawing.PointF]::new($x+94*$scale,$y+49*$scale), [Drawing.PointF]::new($x+85*$scale,$y+49*$scale),
      [Drawing.PointF]::new($x+85*$scale,$y+90*$scale), [Drawing.PointF]::new($x+62*$scale,$y+90*$scale),
      [Drawing.PointF]::new($x+62*$scale,$y+68*$scale), [Drawing.PointF]::new($x+46*$scale,$y+68*$scale),
      [Drawing.PointF]::new($x+46*$scale,$y+90*$scale), [Drawing.PointF]::new($x+23*$scale,$y+90*$scale),
      [Drawing.PointF]::new($x+23*$scale,$y+49*$scale)
    )
    $graphics.FillPolygon($ink, $points)
    $graphics.FillRectangle($cream, $x+32*$scale, $y+54*$scale, 12*$scale, 12*$scale)
    $graphics.FillRectangle($cream, $x+64*$scale, $y+54*$scale, 12*$scale, 12*$scale)
  } finally { $cream.Dispose(); $ink.Dispose(); $accent.Dispose(); $tilePath.Dispose() }
}
foreach ($entry in ($catalog.images | Sort-Object filename -Unique)) {
  $size = [int]([double]($entry.size -split 'x')[0] * [double]($entry.scale -replace 'x',''))
  $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    Draw-KhidmatMark $graphics 0 0 $size $false
    $bitmap.Save((Join-Path $iconRoot $entry.filename), [Drawing.Imaging.ImageFormat]::Png)
  } finally { $graphics.Dispose(); $bitmap.Dispose() }
}
$launchRoot = Join-Path $repoRoot 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
foreach ($asset in @(@{Name='LaunchImage.png'; Scale=1},
    @{Name='LaunchImage@2x.png'; Scale=2}, @{Name='LaunchImage@3x.png'; Scale=3})) {
  $scale = $asset.Scale
  $bitmap = [Drawing.Bitmap]::new(168*$scale,185*$scale,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $graphics = [Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.Clear([Drawing.ColorTranslator]::FromHtml('#0A0C0F'))
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    Draw-KhidmatMark $graphics (36*$scale) (30*$scale) (96*$scale)
    $font = [Drawing.Font]::new('Arial',(10*$scale),[Drawing.FontStyle]::Bold)
    $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#F1EDE4'))
    try {
      $format = [Drawing.StringFormat]::new()
      $format.Alignment = [Drawing.StringAlignment]::Center
      $graphics.DrawString('KHIDMAT',$font,$brush,[Drawing.RectangleF]::new(0,137*$scale,168*$scale,20*$scale),$format)
    } finally { $brush.Dispose(); $font.Dispose(); $format.Dispose() }
    $bitmap.Save((Join-Path $launchRoot $asset.Name),[Drawing.Imaging.ImageFormat]::Png)
  } finally { $graphics.Dispose(); $bitmap.Dispose() }
}
Write-Output 'Android and iOS launch icons now use the Khidmat home-service mark.'
