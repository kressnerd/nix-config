A comprehensive and modular Nix configuration repository for macOS using
nix-darwin and Home Manager. This repository follows organizational
patterns inspired by the nix-config ecosystem while maintaining a
gradual evolution toward increased modularity.

# 🏗️ Repository Structure

For a detailed overview of the repository’s architecture, modularity,
and layering, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). ==
🚀 Quick Start

## Prerequisites

1.  **Install Nix** (if not already installed):

    ``` bash
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    ```

> [!NOTE]
> Xcode Command Line Tools installation is automatically handled by the
> nix-darwin configuration activation script.

## Deployment

1.  **Clone configuration**:

    ``` bash
    git clone <repository-url> <config-directory>
    cd <config-directory>
    ```

2.  **Apply system configuration**:

    ``` bash
    sudo darwin-rebuild switch --flake .#J6G6Y9JK7L
    ```

3.  **Use the convenient alias** (after first successful build):

    ``` bash
    drs  # Shortcut for darwin-rebuild switch
    ```

# 📋 Key Features

## macOS Integration

- **nix-darwin** system management

- **Homebrew** declarative package management

- **macOS system preferences** automation

- **User environment** consistency

## Security & Secrets Management

- **SOPS-nix** integration for encrypted secrets

- **Age** key-based encryption

- **Git identity management** with conditional includes per project
  folder

- **SSH configuration** management

## Modular Architecture

- **Feature-based organization** for easy composition

- **Platform-specific features** with shared base configurations

- **Incremental adoption** of new tools and configurations

- **Clear separation** between system and user configurations

## Development Environment

- **Shell integration** (Zsh with Oh My Zsh, Starship prompt)

- **Editor configurations** (VS Code with extensions, Vim)

- **Terminal setup** (Kitty with shell integration)

- **CLI tooling** (Git, SSH, various utilities)

# 🔧 Configuration Management

## Adding New Features

To add new features, create a new module in the appropriate directory
and import it in your host configuration. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
[docs/HOME-MANAGER.md](docs/HOME-MANAGER.md) for patterns and
examples. === Managing Secrets

Secrets are managed centrally using SOPS and referenced in modules as
needed. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for
details. === Host-Specific Customization

Each host can enable or override features as needed. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the layering and
import structure.

# 🖥️ System Configuration

# 📚 Documentation Structure

- **[README.md](README.md)**: This overview and quick start document

- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**: Architectural
  overview, structure, and modularity

- **[docs/HOME-MANAGER.md](docs/HOME-MANAGER.md)**: Home Manager
  feature documentation

- **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**: Development
  workflow and guidelines == 🔄 Evolution Path

This configuration is designed to grow incrementally:

## Current State

- ✅ **Basic nix-darwin setup** with Home Manager integration

- ✅ **Feature-based organization** for easy composition

- ✅ **SOPS secrets management** for sensitive data

- ✅ **Homebrew integration** for macOS applications

- ✅ **Development environment** setup

## Near Term Goals

- 🔄 **Enhanced module organization** with better abstractions

- 🔄 **Cross-platform compatibility** patterns (preparation for future
  Linux support)

- 🔄 **Custom package overlays** for modified packages

- 🔄 **Service management** for user-level services

## Long Term Vision

- 🚀 **Advanced NixOS integration** (when dual-booting or Linux machines
  are added)

- 🚀 **Custom packages and derivations** for specialized tools

- 🚀 **Multi-host deployment** coordination

- 🚀 **Infrastructure as Code** for cloud resources

The structure supports this evolution while maintaining backwards
compatibility and clear upgrade paths.

# 🤝 Contributing

When adding new features or modifying configurations:

1.  **Follow existing patterns**: Use the established module structure
    and naming conventions

2.  **Document changes**: Update relevant documentation and add inline
    comments

3.  **Test thoroughly**: Verify changes work with
    `darwin-rebuild switch`

4.  **Use feature flags**: Make new features optional and composable

5.  **Maintain backwards compatibility**: Avoid breaking existing
    functionality

## Example Workflow

``` bash
# Create new feature
touch home/dan/features/cli/new-tool.nix

# Edit feature module
$EDITOR home/dan/features/cli/new-tool.nix

# Add to host configuration
$EDITOR home/dan/J6G6Y9JK7L.nix

# Test changes
sudo darwin-rebuild switch --flake .#J6G6Y9JK7L

# Document the feature
$EDITOR docs/HOME-MANAGER.md
```

# 🛠️ Troubleshooting

## Common Issues

1.  **Homebrew failures**: The configuration automatically checks for
    and warns about missing Xcode Command Line Tools

2.  **SOPS errors**: Verify age key exists and is properly configured

3.  **Build failures**: Check flake inputs are up to date with
    `nix flake update`

4.  **Permission issues**: Ensure user has proper sudo access for system
    changes

## Debug Commands

``` bash
# Check flake structure
nix flake show

# Validate configuration
nix flake check

# Build without activation
darwin-rebuild build --flake .#J6G6Y9JK7L

# View current configuration
darwin-rebuild --list-generations
```

# 📖 Additional Resources

- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)

- [Home Manager Manual](https://nix-community.github.io/home-manager/)

- [nix-darwin Manual](https://github.com/nix-darwin/nix-darwin)

- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)

- [Determinate Nix Installer](https://install.determinate.systems/)
