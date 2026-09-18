# Sunum şekillerini HTML'den PNG'ye çevirir (Python gerektirmez).
# Kullanım:  powershell -ExecutionPolicy Bypass -File docs\gorseller\sunum\uret.ps1
# Her şekil 1170 px genişlikte, 2× ölçekte (2340 px) çizilir; alttaki boşluk kırpılır.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$dir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$edge = @(
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
  "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge bulunamadı.' }

# Açık Edge oturumuyla çakışmamak için geçici profil.
$profile = Join-Path $env:TEMP 'uslup_sekil_profili'

function Crop-Bottom([string]$path) {
  $bmp = [System.Drawing.Bitmap]::FromFile($path)
  try {
    $last = 0
    for ($y = $bmp.Height - 1; $y -ge 0; $y--) {
      for ($x = 0; $x -lt $bmp.Width; $x += 5) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -lt 250 -or $c.G -lt 250 -or $c.B -lt 250) { $last = $y; break }
      }
      if ($last -gt 0) { break }
    }
    $h = [Math]::Min($bmp.Height, $last + 56)
    $out = $bmp.Clone([System.Drawing.Rectangle]::new(0, 0, $bmp.Width, $h), $bmp.PixelFormat)
  } finally { $bmp.Dispose() }
  $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose()
}

Get-ChildItem $dir -Filter 'sekil*.html' | ForEach-Object {
  $png = [IO.Path]::ChangeExtension($_.FullName, '.png')
  if (Test-Path $png) { Remove-Item $png -Confirm:$false }
  $url = 'file:///' + ($_.FullName -replace '\\', '/')
  # Edge stderr'e zararsız uyarılar yazar; PowerShell 5.1 bunları hata sayar.
  $args = @('--headless=new', '--disable-gpu', '--hide-scrollbars', "--user-data-dir=`"$profile`"",
            '--force-device-scale-factor=2', '--window-size=1170,1500', '--virtual-time-budget=3000',
            "--screenshot=`"$png`"", "`"$url`"")
  Start-Process -FilePath $edge -ArgumentList $args -Wait -WindowStyle Hidden `
    -RedirectStandardError (Join-Path $env:TEMP 'uslup_sekil_stderr.txt')
  $wait = 0
  while (-not (Test-Path $png) -and $wait -lt 50) { Start-Sleep -Milliseconds 200; $wait++ }
  if (-not (Test-Path $png)) { Write-Warning "Üretilemedi: $($_.Name)"; return }
  Crop-Bottom $png
  $img = [System.Drawing.Image]::FromFile($png); "{0,-24} {1}×{2}" -f $_.BaseName, $img.Width, $img.Height; $img.Dispose()
}
