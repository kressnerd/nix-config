# nix-config

Modular Nix configuration for macOS (nix-darwin) and NixOS (Linux). Started as a basic macOS setup and expanded to include NixOS hosts and VM deployments.

## Repository Structure

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed structure and module organization.

## Quick Start

### Prerequisites

Install Nix using the Determinate Systems installer:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Note: Xcode Command Line Tools are handled automatically during nix-darwin activation.

### Deployment

**macOS (nix-darwin):**

```bash
git clone <repository-url> <config-directory>
cd <config-directory>
sudo darwin-rebuild switch --flake .
```

After the first successful build, use the `drs` alias for subsequent rebuilds.

**NixOS:**

```bash
git clone <repository-url> /etc/nixos
cd /etc/nixos
sudo nixos-rebuild switch --flake .#<hostname>
```

**NixOS VM (using nixos-anywhere):**

See [docs/NIXOS-ANYWHERE-SETUP.md](docs/NIXOS-ANYWHERE-SETUP.md) and [docs/VM-SETUP.md](docs/VM-SETUP.md) for VM deployment.

## What's Included

### System Management

- nix-darwin for macOS system-level configuration
- NixOS for Linux hosts (thiniel, VMs)
- Declarative Homebrew package management (macOS)
- macOS system preferences automation
- Home Manager for user environment (cross-platform)

### Security

- SOPS-nix with age encryption for secrets
- Per-project Git identity management using conditional includes
- Centralized SSH configuration

### Development Setup

- Zsh with Oh My Zsh and Starship prompt
- Kitty terminal with shell integration
- VS Code with extensions managed declaratively
- Vim configuration
- Standard CLI tools (Git, SSH, etc.)

### Organization

- Feature modules in `home/dan/features/`
- Host-specific configs in `hosts/` (J6G6Y9JK7L, thiniel, VMs)
- Platform-specific features (macOS/Linux)
- Shared base configurations in `home/dan/global/`

### VM Deployment

- nixos-anywhere for remote VM installation
- Disko for declarative disk partitioning
- Automated deployment scripts in `scripts/`

## Configuration Management

### Adding Features

Create a module in the appropriate feature directory and import it in your host configuration. Examples and patterns are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/HOME-MANAGER.md](docs/HOME-MANAGER.md).

### Secrets

Managed via SOPS. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for setup details.

### Host Customization

Each host imports features as needed. Check the layering structure in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Module structure and organization
- [HOME-MANAGER.md](docs/HOME-MANAGER.md) - Feature module documentation
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development workflow and guidelines
- [NIXOS-ANYWHERE-SETUP.md](docs/NIXOS-ANYWHERE-SETUP.md) - VM deployment with nixos-anywhere
- [VM-SETUP.md](docs/VM-SETUP.md) - VM configuration details
- [THINIEL-VM-SETUP.md](docs/THINIEL-VM-SETUP.md) - Thiniel VM specific setup

## Common Tasks

### Adding a New Feature

```bash
# Create feature module
touch home/dan/features/cli/new-tool.nix

# Edit module
$EDITOR home/dan/features/cli/new-tool.nix

# Add to host config
$EDITOR home/dan/J6G6Y9JK7L.nix

# Apply changes
sudo darwin-rebuild switch --flake .#J6G6Y9JK7L

# Update documentation
$EDITOR docs/HOME-MANAGER.md
```

### Troubleshooting

Common issues:

- Homebrew failures: Usually means Xcode Command Line Tools need updating
- SOPS errors: Check that age key exists and is configured correctly
- Build failures: Try `nix flake update` to refresh inputs
- Permission errors: Verify sudo access for system changes

Useful debug commands:

```bash
nix flake show                                    # Check flake structure
nix flake check                                   # Validate configuration
darwin-rebuild build --flake .#J6G6Y9JK7L        # Build without activating
darwin-rebuild --list-generations                 # View generations
```

## Current Status

Working configurations:

- nix-darwin on macOS (J6G6Y9JK7L)
- NixOS on thiniel (physical Linux host)
- NixOS VMs with nixos-anywhere deployment
- Feature-based module organization
- SOPS secrets management
- Homebrew integration (macOS)
- Cross-platform Home Manager setup

In progress:

- Better module abstractions
- Custom package overlays
- User-level service management
- Hyprland window manager (Linux)

Future additions:

- Custom derivations
- Multi-host coordination
- Container orchestration

## References

- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Manual](https://github.com/nix-darwin/nix-darwin)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)
- [Determinate Nix Installer](https://install.determinate.systems/)
