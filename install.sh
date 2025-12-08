#!/bin/bash

# Exit on error
set -e

# Determine OS using uname
OS_NAME=$(uname)
case $OS_NAME in
Darwin)
    OS="macos"
    ;;
Linux)
    OS="linux"
    ;;
*)
    echo "Unsupported operating system: $OS_NAME"
    exit 1
    ;;
esac

# Initialize
NIX_EFFECTIVE_BIN_PATH = ""

# Ensure USER variable is set and exported
if [ -z "$USER" ]; then
    CURRENT_USER=$(id -un)
    if [ -z "$CURRENT_USER" ]; then
        echo "Warning: Could not determine current user using 'id -un'. Defaulting USER to OS_NAME."
        USER="$OS_NAME"
    else
        USER="$CURRENT_USER"
    fi
    export USER
    echo "USER variable was not set or could not be determined. Setting and exporting USER to: $USER"
else
    # Ensure USER is exported if it was already set
    export USER
    echo "USER variable is already set to: $USER. Ensuring it is exported."
fi

# Install Nix if not already installed
if ! command -v nix >/dev/null 2>&1; then
    echo "Installing Nix..."
    if [ "$OS" = "macos" ]; then
        curl -L https://nixos.org/nix/install | bash
        # For macOS, source the Nix profile immediately to update PATH in CI.
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        NIX_EFFECTIVE_BIN_PATH="/nix/var/nix/profiles/default/bin"
    else # Linux
        if [ "$IN_DOCKER" = "true" ]; then
            echo "Performing single-user Nix installation (Docker enviroment)..."
            curl -L https://nixos.org/nix/install | bash -s -- --no-daemon
            # Source the Nix profile script to add Nix to PATH for the current shell
            if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
                . "$HOME/.nix-profile/etc/profile.d/nix.sh"
                echo "Sourced Nix profile for single-user (Docker) setup."
            else
                echo "Warning: Nix profile script ($HOME/.nix-profile/etc/profile.d/nix.sh) not found after installation."
                # Fallback PATH export for the current shell
                export PATH="$HOME/.nix-profile/bin:$PATH"
            fi
            NIX_EFFECTIVE_BIN_PATH="$HOME/.nix-profile/bin"
        else # Linux multi-user
            echo "Performing multi-user Nix installation..."
            curl -l https://nixos.org/nix/install | bash -s -- --daemon
            # For Linux multi-user installations, and the default Nix path for the current shell.
            export PATH=/nix/var/nix/profiles/default/bin:$PATH
            NIX_EFFECTIVE_BIN_PATH="/nix/var/nix/profiles/default/bin"
        fi
    fi
else
    echo "Nix is already installed."
    # Determine NIX_EFFECTIVE_BIN_PATH from existing Nix installation
    _nix_executable_path=$(command -v nix)
    if [ -n "$_nix_executable_path" ]; then
        NIX_EFFECTIVE_BIN_PATH=$(dirname "$_nix_executable_path")
        echo "Determined existing NIX_EFFECTIVE_BIN_PATH: $NIX_EFFECTIVE_BIN_PATH"
    else
        echo "Warning: Nix is installed but 'command -v nix' failed to find it. PATH issues might persist."
        # Fallback for safety, through 'command -v nix' in the outer 'if' should be caught this.
        if [ "$OS" = "macos" ]; then
            NIX_EFFECTIVE_BIN_PATH="/nix/var/nix/profiles/default/bin"
        elif [ "$IN_DOCKER" = "true" ]; then
            NIX_EFFECTIVE_BIN_PATH="$HOME/.nix-profile/bin"
        else
            NIX_EFFECTIVE_BIN_PATH="/nix/var/nix/profiles/default/bin"
        fi
        echo "Using fallback NIX_EFFECTIVE_BIN_PATH: $NIX_EFFECTIVE_BIN_PATH"
    fi
fi