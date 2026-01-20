# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix flakes-based dotfiles configuration for cross-platform system management (macOS and Linux). The project uses Nix for declarative system configuration, Home Manager for user-level settings, and includes support for NixOS servers and nix-darwin for macOS.

**Note:** This repository is in early development stages. The `flake.nix` references several directories that don't exist yet (`hosts/`, `lib/`, `named-hosts/`, `overlays/`, `dotagents/`, `devenv.nix`, `treefmt.toml`).

## Common Commands

### Initial Installation
```bash
# Full automated installation (installs Nix if needed, then runs make install)
./install.sh

# Manual installation steps
make install        # Sets up full environment (setup, flake-update, build, switch, shell-install)
```

### Development Workflow
```bash
make setup-dev      # Set up local development environment (Nix + submodules + shell)
make dev            # Enter the Nix dev shell (uses devenv)
make check          # Run all validation checks (flake check, format check, lua check)
make format         # Format all files using treefmt
```

### Configuration Management
```bash
make switch         # Apply configuration changes and restart services
make update         # Update flake inputs, rebuild, and switch
make build          # Build Nix configuration without activating
```

### Testing
```bash
make test           # Run all tests (shell)
make shell-test     # Run shell script tests (ShellSpec)
```

### Secrets Management (Agenix)
```bash
make encrypt-key HOST=galactica KEY_FILE=~/.ssh/id_ed25519  # Encrypt a key
make decrypt-key HOST=galactica KEY_FILE=id_ed25519          # Decrypt a key
make rekey HOST=galactica                                     # Rekey all secrets
```

### Named Host Switching
```bash
make switch-galactica  # Switch to named host configuration (galactica, kyber, etc.)
```

### Offline Mode
```bash
make nix-build-offline   # Build in offline mode
make nix-switch-offline  # Switch in offline mode
```

## Architecture

### Nix Flake Structure

The flake uses `flake-parts` for modular configuration. Key outputs:

- **darwinConfigurations**: macOS system configurations (nix-darwin)
- **nixosConfigurations**: NixOS server configurations
- **homeConfigurations**: User-level configurations for Linux desktops (Home Manager)

### Supported Systems

- `aarch64-darwin` - macOS ARM64 (Apple Silicon)
- `aarch64-linux` - Linux ARM64
- `x86_64-linux` - Linux x86_64

### Configuration Type Detection

The Makefile automatically detects the configuration type based on OS:
- **Darwin (macOS)**: Uses `darwinConfigurations`
- **Linux with `/etc/NIXOS`**: Uses `nixosConfigurations`
- **Linux without NixOS**: Uses `homeConfigurations`

### Named Hosts

Special host configurations are defined in `named-hosts/`:
- **galactica** - macOS machine (Shun's MacBook M4)
- **kyber** - Linux machine (hostname: kyber)

The Makefile auto-detects these hosts by ComputerName/hostname for automatic switching.

### Key Inputs

- **nix-darwin** - Darwin system configuration
- **home-manager** - User-level dotfiles management
- **agenix** - Secrets encryption (Age-based)
- **devenv** - Development environment management
- **nur** - Nix User Repository

### Dotagents Integration

The Makefile includes `dotagents/Makefile` (a submodule) for command/skill management. Use `make sync` to sync dotagents.

## Services

### macOS (launchd)
Services are managed via launchd agents in `~/Library/LaunchAgents/`:
- brew-upgrader, clawdbot, cliproxyapi, code-syncer, dotfiles-updater, neverssl-keepalive, ollama

Use `make services` or `make launchctl` to restart all.

### Linux (systemd)
User services are managed via systemd:
- cliproxyapi, clawdbot, code-syncer, dotfiles-updater, ollama

Use `make services` or `make systemctl` to restart all.

## Environment Variables

- `CI` - Set to "true" in CI environments (affects build/switch behavior)
- `IN_DOCKER` - Set to "true" in Docker environments (triggers single-user Nix)
- `NIX_CONFIG_TARGET` - Override config type detection (nixos or home)
- `HOST` - Specify a named host to switch to
- `USER` - Username for configuration (defaults to `whoami` output)

## Formatting

The project uses `treefmt-nix` with the following formatters:
- Nix: `nixfmt-rfc-style`
- Biome: `biome`
- JSON: `jsonfmt`
- Shell: `shfmt`
- TOML: `taplo`
- YAML: `yamlfmt`

Configuration is in `treefmt.toml`.
