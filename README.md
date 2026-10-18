# nix-config

Modular Nix configuration for macOS (nix-darwin) and NixOS (Linux). Started as a basic macOS setup and expanded to include NixOS hosts and VM deployments.

## Repository Structure

```
flake.nix / flake.lock
├── hosts/
│   ├── common/
│   │   ├── global/         (shared NixOS base: timezone, locale, NetworkManager, flakes)
│   │   ├── optional/       (optional NixOS modules: virtualisation, docker)
│   │   └── users/          (shared NixOS user definition)
│   ├── J6G6Y9JK7L/         (aarch64-darwin — macOS workstation)
│   ├── thiniel/            (x86_64-linux — ThinkPad X270)
│   ├── cupix001/            (x86_64-linux — netcup KVM VPS edge gateway)
│   └── nixos-vm-minimal/   (aarch64-linux — minimal test VM)
├── home/
│   └── dan/
│       ├── global/         (HM base: stateVersion, htop, ripgrep)
│       ├── features/       (composable feature modules)
│       │   ├── cli/
│       │   ├── development/
│       │   ├── linux/
│       │   ├── macos/
│       │   └── productivity/
│       ├── dotfiles/
│       │   └── doom.d/     (Doom Emacs config)
│       ├── J6G6Y9JK7L.nix
│       ├── thiniel.nix
│       ├── cupix001.nix
│       └── nixos-vm-minimal.nix
├── lib/
│   └── helpers.nix         (mkPkgsUnstable, mkFirefoxExtensions)
├── overlays/               (custom nixpkgs overlays)
├── pkgs/                   (custom packages)
├── modules/
│   ├── nixos/              (reusable NixOS modules)
│   └── home-manager/       (reusable HM modules)
├── templates/
│   └── host/               (new NixOS host scaffold)
├── scripts/                (VM build and deploy scripts)
└── docs/                   (detailed documentation)
```

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

Hosts whose network values are held outside the repository (`adlerkopf`,
`cupix001`) must add the private input override, or the build uses the public
documentation-range placeholders:

```bash
sudo nixos-rebuild switch --flake .#<hostname> \
  --override-input private git+file:///home/dan/dev/PRIVATE/nix-private
```

The per-host `rebuild` alias runs a preflight that refuses to deploy when the
override supplied no values. See
[docs/arc42/adr/ADR-0001-private-data-strategy.md](docs/arc42/adr/ADR-0001-private-data-strategy.md).

Hosts that install the private `givn` tool (`thiniel`, `J6G6Y9JK7L`) must also
override the `givn` input; without it the public stub supplies no overlay and
the host builds without `givn`:

```bash
sudo nixos-rebuild switch --flake .#<hostname> \
  --override-input givn github:kressnerd/givn
```

Their `rebuild` aliases (`nrs`/`nrt`/`nrb`, `drs`) carry the override.

**NixOS VM (using nixos-anywhere):**

See [docs/NIXOS-ANYWHERE-SETUP.md](docs/NIXOS-ANYWHERE-SETUP.md) and [docs/VM-SETUP.md](docs/VM-SETUP.md) for VM deployment.

## What's Included

### System Management

- nix-darwin for macOS system-level configuration
- NixOS for Linux hosts (thiniel, VMs)
- Shared NixOS base config in `hosts/common/` (timezone, locale, Nix settings)
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
- **Doom Emacs** with Henrik Lissner's recommended Nix integration
  - Declarative system dependencies via Nix
  - Emacs packages managed by straight.el
  - Automatic doom sync on Home Manager activation
  - Full LSP support (Nix, Python, Rust, TypeScript, etc.)
  - Config dotfiles at `home/dan/dotfiles/doom.d/`
- VS Code with extensions managed declaratively
- Vim configuration
- Standard CLI tools (Git, SSH, etc.)

### Organization

- Feature modules in `home/dan/features/`
- Shared NixOS config in `hosts/common/`
- Host-specific configs in `hosts/` (J6G6Y9JK7L, thiniel, VMs)
- Platform-specific features (macOS/Linux)
- Shared base configurations in `home/dan/global/`

### VM Deployment

- nixos-anywhere for remote VM installation
- Disko for declarative disk partitioning
- Deployment scripts in `scripts/`

## Configuration Management

### Adding Features

Create a module in the appropriate feature directory and import it in your host configuration. Examples and patterns are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/HOME-MANAGER.md](docs/HOME-MANAGER.md).

### Adding a New Host

Use the template scaffold:

```bash
cp -r templates/host hosts/<new-hostname>
# Edit hosts/<new-hostname>/default.nix
# Create hosts/<new-hostname>/hardware.nix
# Create home/dan/<new-hostname>.nix
# Register in flake.nix
```

### Secrets

Managed via SOPS. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for setup details.

### Host Customization

Each host imports `hosts/common/global` (NixOS only) plus optional modules and features as needed. Check the layering structure in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### Host Setup — hosts with private values

Host-specific network values are never committed. They live in a separate
private flake (`~/dev/PRIVATE/nix-private`) that supplies one
`nixosModules.<host>` per host, and the public flake's `private` input defaults
to the in-tree stub `private-stub/`.

Adding a host that has private values therefore touches both sides:

1. Add a no-op module for the host to `private-stub/flake.nix` (it asserts the
   host's declared values are documentation-range placeholders or empty).
2. Add the real module to `~/dev/PRIVATE/nix-private/flake.nix`.
3. Wire `inputs.private.nixosModules.<host>` into the host's
   `nixosConfigurations` entry in `flake.nix`.
4. Add the `rebuild` preflight alias to `home/dan/<host>.nix`.

`nix flake check` and CI always evaluate with the stub, so no private access is
needed to build or review the repository.

### Host Setup — hosts with the private givn tool

The `givn` tool lives in the private flake `github:kressnerd/givn`. The public
flake's `givn` input defaults to the in-tree `givn-stub/`, which has no
`overlays` output and no package, so evaluation without the override applies no
givn overlay and installs no `givn`. Supply the real input on a deploy:

```bash
sudo nixos-rebuild switch --flake .#<hostname> \
  --override-input givn github:kressnerd/givn
```

Host invariants check for `givn` only when the real input is supplied; there is
no fake package in the public stub. See `flake.nix` and
`home/dan/features/development/givn.nix`.

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Module structure and organization
- [HOME-MANAGER.md](docs/HOME-MANAGER.md) - Feature module documentation
- [DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development workflow and guidelines
- [DOOM-EMACS-SETUP-GUIDE.md](docs/DOOM-EMACS-SETUP-GUIDE.md) - Doom Emacs setup and usage
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
- SOPS errors: Verify `.sops.yaml` recipient rules and the `sops.secrets` declarations (never inspect age private-key files or decrypt on an agent's behalf)
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
- Shared NixOS base config via `hosts/common/`
- SOPS secrets management
- Homebrew integration (macOS)
- Cross-platform Home Manager setup
- Doom Emacs with Henrik Lissner's recommended approach
- Custom overlays applied to all hosts

In progress:

- Better module abstractions
- Custom package overlays
- User-level service management
- Hyprland window manager (Linux)

Future additions:

- Custom derivations in `pkgs/`
- Scripts migration to Nix derivations
- Multi-host coordination
- Container orchestration

## References

- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [nix-darwin Manual](https://github.com/nix-darwin/nix-darwin)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)
- [Determinate Nix Installer](https://install.determinate.systems/)
