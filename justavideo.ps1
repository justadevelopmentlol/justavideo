param([Parameter(Position=0)][string]$Url, [Parameter(Position=1)][string]$Dest)

$ErrorActionPreference = "Stop"
if (-not $Url -or $Url -eq "--help" -or $Url -eq "-h") { Write-Host "Usage: justavideo <video-url> [destination]"; exit 0 }
if (-not $Dest) { $Dest = Join-Path $HOME "Downloads" }
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) { Write-Host "yt-dlp is not installed. Run the installer again."; exit 1 }

$formats = @(& yt-dlp --no-playlist -F $Url | ForEach-Object { if ($_ -match '^\s*(\S+)\s+(\S+)\s+(\d+x\d+)\s+(.*)$' -and $Matches[4] -notmatch 'images') { [PSCustomObject]@{ Id=$Matches[1]; Label="$($Matches[3]) $($Matches[2])"; VideoOnly=$Matches[4] -match 'video only' } } })
if ($formats.Count -eq 0) { Write-Host "No video formats were found."; exit 1 }

$selected = 0
$confirmed = $false
while (-not $confirmed) {
    Clear-Host
    Write-Host "Select a resolution"
    Write-Host "Use the arrow keys and Enter. Press q to cancel."
    Write-Host ""
    for ($index = 0; $index -lt $formats.Count; $index++) { $prefix = if ($index -eq $selected) { "›" } else { " " }; Write-Host "$prefix $($formats[$index].Label)" }
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.VirtualKeyCode) { 38 { if ($selected -gt 0) { $selected-- } }; 40 { if ($selected -lt $formats.Count - 1) { $selected++ } }; 13 { $confirmed = $true }; 27 { exit 0 }; default { if ($key.Character -eq 'q' -or $key.Character -eq 'Q') { exit 0 } } }
}

$format = $formats[$selected]
$selector = if ($format.VideoOnly) { "$($format.Id)+bestaudio[ext=m4a]/$($format.Id)+bestaudio/$($format.Id)" } else { $format.Id }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
& yt-dlp --no-playlist -f $selector --merge-output-format mp4 --embed-thumbnail --add-metadata --progress -o "$Dest\%(title)s.%(ext)s" $Url
Write-Host "Saved to $Dest"
