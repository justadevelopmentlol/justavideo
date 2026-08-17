$ErrorActionPreference = "Stop"

$RepoRaw = "https://raw.githubusercontent.com/realryz/justavideo/refs/heads/main/install.ps1"
$InstallDir = "$HOME\.ryz"
$BinDir = "$InstallDir\bin"

function Show-Progress {
    param([string]$Message)
    Write-Host -NoNewline "$Message "
    for ($i = 0; $i -lt 20; $i++) {
        Write-Host -NoNewline "#"
        Start-Sleep -Milliseconds 20
    }
    Write-Host " done"
}

Write-Host "Installing ryz for windows"
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

Show-Progress "Downloading ryz"
Invoke-WebRequest -Uri "$RepoRaw/bin/ryz.ps1" -OutFile "$BinDir\ryz.ps1"

$WrapperPath = "$BinDir\ryz.cmd"
"@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"$BinDir\ryz.ps1`" %*" | Set-Content -Path $WrapperPath -Encoding ASCII

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
