#!/bin/bash

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

log_info "🚀 Starting dotfiles setup..."

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log_info "Homebrew is already installed."
fi

# Install core applications via Brewfile.core
log_info "Installing essential applications..."
if [ -f "brew/Brewfile.core" ]; then
    brew bundle --file=brew/Brewfile.core
else
    log_error "brew/Brewfile.core not found."
    exit 1
fi

# Configure input sources
log_warn "Please configure Google Japanese Input manually:"
log_info "1. Open System Settings > Keyboard > Input Sources"
log_info "2. Click '+' button and add 'Google Japanese Input'"
log_info "3. Remove the default input source"

# Optional: Install additional applications
if [ -f "brew/Brewfile" ]; then
    log_info "Would you like to install additional applications? [y/N]"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        log_info "Installing additional applications..."
        brew bundle --file=brew/Brewfile
    fi
fi

# Optional: Apply MacOS optimized settings
if [ -f "macos/apply.sh" ]; then
    log_info "Would you like to apply optimized MacOS settings? [y/N]"
    log_info "(Faster keyboard, trackpad, Dock, and animations)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        log_info "Applying MacOS settings..."
        bash "macos/apply.sh"
        log_info "MacOS settings applied successfully!"
    fi
fi

log_info "✨ Setup completed!" 
