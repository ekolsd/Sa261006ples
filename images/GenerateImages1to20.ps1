Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$outputDir = Join-Path $PWD "CMS_Images"
$zipPath   = Join-Path $PWD "CMS_1-20.zip"

if (Test-Path $outputDir) { Remove-Item -Path $outputDir -Recurse -Force }
if (Test-Path $zipPath)   { Remove-Item -Path $zipPath -Force }
New-Item -ItemType Directory -Path $outputDir | Out-Null

$width  = 96
$height = 96
$bgColor = [System.Drawing.Color]::FromArgb(255, 0, 0)
$fgBrush = [System.Drawing.Brushes]::White

for ($i = 1; $i -le 20; $i++) {
    $text = $i.ToString()
    $bmp  = New-Object System.Drawing.Bitmap($width, $height)
    $g    = [System.Drawing.Graphics]::FromImage($bmp)
    
    $g.Clear($bgColor)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    
    # Binary search to find maximum font size fitting inside 96x96 bounds
    $minSize = 10.0
    $maxSize = 120.0
    $bestSize = 10.0
    
    for ($step = 0; $step -lt 25; $step++) {
        $testSize = ($minSize + $maxSize) / 2.0
        $testFont = New-Object System.Drawing.Font("Consolas", $testSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $textSize = $g.MeasureString($text, $testFont, [System.Drawing.PointF]::new(0, 0), [System.Drawing.StringFormat]::GenericTypographic)
        
        # Keep 2px margin buffer inside dimensions
        if ($textSize.Width -le ($width - 4) -and $textSize.Height -le ($height - 4)) {
            $bestSize = $testSize
            $minSize  = $testSize
        } else {
            $maxSize  = $testSize
        }
        $testFont.Dispose()
    }
    
    $font = New-Object System.Drawing.Font("Consolas", $bestSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf   = New-Object System.Drawing.StringFormat([System.Drawing.StringFormat]::GenericTypographic)
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $rect = New-Object System.Drawing.RectangleF(0, 0, $width, $height)
    $g.DrawString($text, $font, $fgBrush, $rect, $sf)
    
    $filePath = Join-Path $outputDir "CMS$i.png"
    $bmp.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $font.Dispose()
    $sf.Dispose()
    $g.Dispose()
    $bmp.Dispose()
}

# Compress into CMS_1-20.zip
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir, $zipPath)
Write-Host "Successfully generated CMS1.png through CMS20.png and created $zipPath"