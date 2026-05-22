Add-Type -AssemblyName System.Drawing

$src = 'D:\new_henan_exam\icon_source.jpg'
$img = [System.Drawing.Image]::FromFile($src)

$sizes = @(
    @{ Dir = 'mipmap-mdpi';    Size = 48 },
    @{ Dir = 'mipmap-hdpi';    Size = 72 },
    @{ Dir = 'mipmap-xhdpi';   Size = 96 },
    @{ Dir = 'mipmap-xxhdpi';  Size = 144 },
    @{ Dir = 'mipmap-xxxhdpi'; Size = 192 }
)

$basePath = 'D:\new_henan_exam\android\app\src\main\res'

foreach ($item in $sizes) {
    $dir = Join-Path $basePath $item.Dir
    $out = Join-Path $dir 'ic_launcher.png'
    $size = $item.Size

    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($img, 0, 0, $size, $size)

    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()

    Write-Output "Created: $out (${size}x${size})"
}

$img.Dispose()
Write-Output 'All icons generated successfully.'
