param([Parameter(Position=0)][string]$Url, [Parameter(Position=1)][string]$Dest)

$ErrorActionPreference = "Stop"

function Invoke-ColoredYtDlp {
    param([string[]]$Arguments)
    & yt-dlp @Arguments 2>&1 | ForEach-Object {
        $line = $_.ToString()
        $color = "White"
        if ($line.StartsWith("[youtube]")) { $color = "Red" }
        elseif ($line.StartsWith("[info]")) { $color = "Yellow" }
        elseif ($line.StartsWith("[download]")) { $color = "Blue" }
        elseif ($line.StartsWith("[error]") -or $line.StartsWith("ERROR:")) { $color = "Red" }
        elseif ($line.StartsWith("[Metadata]") -or $line.StartsWith("[metadata]")) { $color = "Magenta" }
        elseif ($line.StartsWith("[ExtractAudio]") -or $line.StartsWith("[Merger]")) { $color = "Cyan" }
        elseif ($line.StartsWith("[warning]")) { $color = "Yellow" }
        elseif ($line.StartsWith("[debug]")) { $color = "DarkGray" }
        Write-Host $line -ForegroundColor $color
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not $Url -or $Url -eq "--help" -or $Url -eq "-h") {
    Write-Host "Usage: justavideo <video-url> [destination]"
    exit 0
}

if (-not $Dest) { $Dest = Join-Path $HOME "Downloads" }
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "yt-dlp is not installed. Run the installer again."
    exit 1
}

function Select-Option {
    param([string]$Title, [object[]]$Options)
    $selected = 0
    while ($true) {
        Clear-Host
        Write-Host $Title
        Write-Host "Use the arrow keys and Enter. Press q to cancel."
        Write-Host ""
        for ($index = 0; $index -lt $Options.Count; $index++) {
            $prefix = if ($index -eq $selected) { "›" } else { " " }
            if ($index -eq $selected) {
                Write-Host "$prefix $($Options[$index])" -ForegroundColor Green
            } else {
                Write-Host "$prefix $($Options[$index])" -ForegroundColor White
            }
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { if ($selected -gt 0) { $selected-- } }
            40 { if ($selected -lt $Options.Count - 1) { $selected++ } }
            13 { return $selected }
            27 { exit 0 }
            default { if ($key.Character -eq 'q' -or $key.Character -eq 'Q') { exit 0 } }
        }
    }
}

$mode = Select-Option "Choose a format" @("MP4 video", "MP3 audio")
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

if ($mode -eq 0) {
    $formats = @(& yt-dlp --extractor-args "youtube:player_client=web_embedded" --no-playlist -F $Url | ForEach-Object {
        if ($_ -match '^\s*(\S+)\s+(mp4)\s+(\d+x\d+)\s+(.*)$' -and $Matches[4] -notmatch 'images') {
            [PSCustomObject]@{ Id = $Matches[1]; Label = "$($Matches[3]) mp4"; VideoOnly = $Matches[4] -match 'video only'; Resolution = $Matches[3] }
        }
    } | Group-Object Resolution | ForEach-Object { $_.Group[0] })

    if ($formats.Count -eq 0) { Write-Host "No MP4 formats were found."; exit 1 }
    $format = $formats[(Select-Option "Choose a resolution" ($formats | ForEach-Object { $_.Label }))]
    $selector = if ($format.VideoOnly) { "$($format.Id)+bestaudio[ext=m4a]/$($format.Id)+bestaudio/$($format.Id)" } else { $format.Id }
    Invoke-ColoredYtDlp @("--extractor-args", "youtube:player_client=web_embedded", "--no-playlist", "-f", $selector, "--merge-output-format", "mp4", "--embed-thumbnail", "--add-metadata", "--progress", "--newline", "-o", "$Dest\%(title)s.%(ext)s", $Url)
} else {
    $qualities = @("320 kbps", "256 kbps", "192 kbps", "128 kbps")
    $quality = (Select-Option "Choose MP3 quality" $qualities)
    $bitrates = @("320K", "256K", "192K", "128K")
    Invoke-ColoredYtDlp @("--extractor-args", "youtube:player_client=web_embedded", "--no-playlist", "-x", "--audio-format", "mp3", "--audio-quality", $bitrates[$quality], "--embed-thumbnail", "--add-metadata", "--progress", "--newline", "-o", "$Dest\%(title)s.%(ext)s", $Url)
}

Write-Host "Saved to $Dest"
