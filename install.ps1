$ErrorActionPreference = "Stop"

$DownloadBase = "https://cloud.ryz.wtf"
$InstallDir = "$HOME\.justavideo"
$BinDir = "$InstallDir\bin"

function Show-Progress {
    param([string]$Message)
    $steps = 24
    $bar = ""
    for ($i = 1; $i -le $steps; $i++) {
        $bar += "="
        $percent = [math]::Floor($i * 100 / $steps)
        Write-Host -NoNewline ("`r{0} [{1,-24}] {2,3}%" -f $Message, $bar, $percent)
        Start-Sleep -Milliseconds 20
    }
    Write-Host ""
}

Write-Host "Installing justavideo for Windows"
Write-Host ""

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Show-Progress "Installing yt-dlp"
    winget install --id yt-dlp.yt-dlp -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    Show-Progress "Installing ffmpeg"
    winget install --id Gyan.FFmpeg -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    Show-Progress "Installing yt-dlp and ffmpeg"
    choco install yt-dlp ffmpeg -y | Out-Null
} else {
    Write-Host "No supported package manager found. Please install yt-dlp and ffmpeg manually."
    exit 1
}

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

Show-Progress "Downloading justavideo"
Invoke-WebRequest -Uri "$DownloadBase/justavideo.ps1" -OutFile "$BinDir\justavideo.ps1"

$WrapperPath = "$BinDir\justavideo.cmd"
"@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$BinDir\justavideo.ps1`" %*" | Set-Content -Path $WrapperPath -Encoding ASCII

$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$BinDir", "User")
}

Write-Host ""
Write-Host "justavideo installed successfully"
Write-Host "Restart your terminal for PATH changes to take effect"
Write-Host ""
Write-Host "Usage:"
Write-Host "  justavideo https://youtu.be/VIDEO_ID"
