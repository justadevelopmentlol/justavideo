#!/usr/bin/env bash
set -e

REPO_RAW="https://raw.githubusercontent.com/realryz/justavideo/refs/heads/main/install.sh"
INSTALL_DIR="$HOME/.ryz"
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

echo "Installing ryz for $PLATFORM"
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
progress "Downloading ryz"
curl -fsSL "$REPO_RAW/bin/ryz" -o "$BIN_DIR/ryz"
chmod +x "$BIN_DIR/ryz"

SHELL_RC="$HOME/.zshrc"
IS_ZSH=true
if [[ "$SHELL" != *zsh* ]]; then
  SHELL_RC="$HOME/.bash_profile"
  IS_ZSH=false
fi

touch "$SHELL_RC"

if ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
fi

if [[ "$IS_ZSH" == true ]]; then
  if ! grep -q "alias ryz=" "$SHELL_RC" 2>/dev/null; then
    echo "alias ryz=\"noglob $BIN_DIR/ryz\"" >> "$SHELL_RC"
  fi
fi

echo ""
echo "justavideo installed successfully"
echo "Restart your terminal or run: source $SHELL_RC"
echo ""
echo "Usage:"
echo "justavideo https://youtu.be/VIDEO_ID"
