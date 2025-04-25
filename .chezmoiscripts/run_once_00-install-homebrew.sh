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

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH if needed
    if [[ $(uname -m) == "arm64" ]]; then
        # For Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        # For Intel
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    log_info "Homebrew is already installed."
fi 
