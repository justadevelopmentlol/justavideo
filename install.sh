#!/usr/bin/env bash
set -e

DOWNLOAD_BASE="https://cloud.ryz.wtf"
INSTALL_DIR="$HOME/.justavideo"
BIN_DIR="$INSTALL_DIR/bin"

progress() {
  local msg="$1"
  local steps=24
  local bar=""
  local percent
  for ((i = 1; i <= steps; i++)); do
    bar="${bar}="
    percent=$((i * 100 / steps))
    printf "\r\033[K%s [%-24s] %3d%%" "$msg" "$bar" "$percent"
    sleep 0.02
  done
  printf "\n"
}

detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform)

if [[ "$PLATFORM" == "unknown" ]]; then
  echo "Unsupported platform."
  exit 1
fi

echo "Installing justavideo for $PLATFORM"
echo ""

if [[ "$PLATFORM" == "macos" ]]; then
  if ! command -v brew &> /dev/null; then
    progress "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1
  fi
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  progress "Installing yt-dlp and ffmpeg"
  brew install yt-dlp ffmpeg > /dev/null 2>&1
else
  if command -v apt-get &> /dev/null; then
    progress "Installing yt-dlp and ffmpeg"
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install -y ffmpeg python3-pip > /dev/null 2>&1
    sudo pip3 install -U yt-dlp > /dev/null 2>&1
  elif command -v dnf &> /dev/null; then
    progress "Installing yt-dlp and ffmpeg"
    sudo dnf install -y ffmpeg python3-pip > /dev/null 2>&1
    sudo pip3 install -U yt-dlp > /dev/null 2>&1
  elif command -v pacman &> /dev/null; then
    progress "Installing yt-dlp and ffmpeg"
    sudo pacman -Sy --noconfirm yt-dlp ffmpeg > /dev/null 2>&1
  else
    echo "No supported package manager found. Please install yt-dlp and ffmpeg manually."
    exit 1
  fi
fi

mkdir -p "$BIN_DIR"
progress "Downloading justavideo"
curl -fsSL "$DOWNLOAD_BASE/justavideo" -o "$BIN_DIR/justavideo"
chmod +x "$BIN_DIR/justavideo"

for SHELL_RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  touch "$SHELL_RC"
  if ! grep -Fq "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
  fi
done

if ! grep -Fq "alias justavideo=" "$HOME/.zshrc" 2>/dev/null; then
  echo "alias justavideo=\"noglob $BIN_DIR/justavideo\"" >> "$HOME/.zshrc"
fi

echo ""
echo "justavideo installed successfully"
echo "Open a new terminal window."
echo ""
echo "Usage:"
echo "justavideo https://youtu.be/VIDEO_ID"
