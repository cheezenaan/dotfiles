# dotfiles

## Installation

**1. Install Homebrew (if not already installed):**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Add Homebrew to your PATH (instructions provided by the installer)
# Example for zsh:
# echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
# eval "$(/opt/homebrew/bin/brew shellenv)"
```

**2. Install chezmoi and apply dotfiles:**

Run the following command:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/cheezenaan/dotfiles.git
```

This single command will:

1.  Install chezmoi if it's not present.
2.  Clone the dotfiles repository.
3.  Execute the setup scripts (`run_once_*.sh`) in `.chezmoiscripts/`:
    *   Install Homebrew.
    *   Install essential applications (`Brewfile.core`).
    *   Optionally install additional applications (`Brewfile`).
    *   Optionally apply optimized macOS settings.
4.  Apply the dotfiles managed by chezmoi.

## Applications to be installed

### Essential Applications (brew/Brewfile.core)

The following applications will be installed automatically:

- CLI
    - Homebrew
- GUI
    - Google Chrome
    - Google Japanese Input
    - 1Password

### Additional Applications (brew/Brewfile)

You can choose whether to install additional applications during installation.
Please refer to `brew/Brewfile` for details.

You can customize the applications to be installed by editing these files as needed.

## License

MIT 
