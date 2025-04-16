# dotfiles

## Installation

Just run the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/cheezenaan/dotfiles/main/install.sh)"
```

After installation, apply the dotfiles configuration with:

```bash
chezmoi apply
```

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
