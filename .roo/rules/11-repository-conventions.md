# Repository Conventions — nix-config

## Scope

This rule defines the directory structure, file organization, and composition patterns specific to this nix-config repository. All modes operating on this repository MUST respect these conventions.

## Directory Structure

```
nix-config/
├── flake.nix                    # Central flake — all configurations
├── flake.lock                   # Pinned dependency versions
├── shell.nix                    # Development shell
├── .sops.yaml                   # SOPS encryption rules
├── hosts/<hostname>/            # NixOS / nix-darwin host configs
│   ├── default.nix              # Host entry point
│   ├── hardware.nix             # Hardware config (READ-ONLY)
│   ├── secrets.yaml             # SOPS-encrypted secrets
│   ├── disko.nix                # Disk partitioning (optional)
│   └── <service>.nix            # Service-specific modules (optional)
├── home/dan/                    # Home Manager configurations
│   ├── <hostname>.nix           # Per-host user profile (entry point)
│   ├── global/default.nix       # Shared baseline (stateVersion, core tools)
│   ├── global/linux.nix         # Linux-only global settings
│   └── features/                # Composable feature modules
│       ├── cli/                 # Terminal tools
│       ├── development/         # Dev environment
│       ├── linux/               # Linux-only features
│       ├── macos/               # macOS-only features
│       └── productivity/        # GUI/productivity apps
├── lib/                         # Shared Nix helpers
├── overlays/                    # Nixpkgs overlays
│   ├── default.nix              # Aggregator (merges sub-overlays)
│   └── <name>/default.nix       # Individual overlay
├── pkgs/                        # Custom package derivations
├── modules/                     # Custom NixOS/HM modules (optional)
├── scripts/                     # Build/deploy shell scripts
└── docs/                        # Project documentation
```

## File Conventions

### Host Configuration (`hosts/<hostname>/`)

- `default.nix` — Entry point; imports hardware, services, input modules
- Function signature: `{ config, lib, pkgs, inputs, ... }:`
- Imports: hardware config, sops, impermanence, nixos-hardware (as applicable)
- `hardware.nix` — **READ-ONLY** unless explicitly modifying kernel modules or filesystems
- `secrets.yaml` — SOPS-encrypted; always adjacent to `default.nix`
- Server hosts split concerns into dedicated files per service (e.g., `firewall.nix`, `nginx.nix`, `headscale.nix`)

### Home Manager Profiles (`home/dan/<hostname>.nix`)

- Each host has a dedicated profile file
- Imports `./global/default.nix` as baseline
- Selectively imports features from `./features/<category>/<name>.nix`
- Sets `home.username`, `home.homeDirectory`
- Configures SOPS secrets (path: `../../hosts/<hostname>/secrets.yaml`)
- Defines host-specific shell aliases for rebuild commands

### Feature Modules (`home/dan/features/<category>/<name>.nix`)

- Function signature: `{ pkgs, ... }:` or `{ config, pkgs, lib, ... }:`
- Self-contained; one concern per file
- Cross-platform by default; platform-specific features in `linux/` or `macos/`
- Use `home.packages` for package installation
- Use `programs.<name>` for Home Manager program configuration

### Overlays (`overlays/`)

- Each subdirectory exports a `final: prev:` function
- `default.nix` aggregates all sub-overlays with `//` composition
- Custom extensions to `pkgs` namespace

### Libraries (`lib/`)

- Shared helper functions
- Currently: `pkgs-unstable.nix` (unstable channel import), `firefox-extensions.nix` (extension sets)

## Composition Strategy

```
flake.nix
  └─ nixosConfigurations.<host>
       ├─ hosts/<host>/default.nix          (system config)
       │    ├─ hardware.nix
       │    ├─ disko.nix (optional)
       │    └─ <service>.nix (optional)
       └─ home-manager.users.dan
            └─ home/dan/<host>.nix          (user config)
                 ├─ global/default.nix      (shared baseline)
                 └─ features/<cat>/<name>.nix  (composable features)
```

**Key rule**: Features are composed **per host profile**, not globally. Each host profile selectively imports only the features needed for that machine.

## Flake Output Structure

- `nixosConfigurations` — NixOS hosts (7 configurations)
- `darwinConfigurations` — nix-darwin hosts (1 configuration)
- `overlays` — Nixpkgs overlays
- `packages` — Custom packages (per system)
- `devShells` — Development environments

**Note**: `homeConfigurations` is not a separate flake output; Home Manager is integrated as a NixOS/nix-darwin module via `home-manager.users.dan` within each host configuration.

## Platform Conventions

| Platform | Config Location | Rebuild Command |
|----------|----------------|-----------------|
| NixOS | `hosts/<host>/default.nix` | `sudo nixos-rebuild switch --flake .#<host>` |
| nix-darwin (macOS) | `hosts/<host>/default.nix` | `darwin-rebuild switch --flake .#<host>` |
| Home Manager (standalone) | `home/dan/<host>.nix` | `home-manager switch --flake .#<user@host>` |

## Special Args Convention

All configurations pass these via `specialArgs`:

- `inputs` — Flake inputs
- `outputs` — Flake outputs
- `pkgs-unstable` — Unstable channel packages (via `lib/pkgs-unstable.nix`)

## Home Manager Integration

- Always: `useGlobalPkgs = true; useUserPackages = true;`
- Integrated as NixOS/nix-darwin module, not standalone
- `stateVersion` set in `home/dan/global/default.nix`

## Documentation Policy

- Top-level README: minimal — structure overview, quickstart, how to add host/user, update inputs & rebuild
- Link upstream docs (NixOS manual, Home Manager options) only when needed; do not duplicate
- Avoid verbose docs; keep concise, operational instructions
- Do not duplicate overlay/package code in documentation

## Development Workflow

- devShell provides: `nixfmt`, `alejandra`, `statix`, `nil`, `deadnix`
- Pre-commit hooks: use if present; otherwise minimal format checks
- Format check: run formatter before committing Nix files

## Naming Conventions

- Host directories: lowercase, hyphenated (e.g., `cupix001-vm`, `thiniel`)
- Feature files: lowercase, hyphenated (e.g., `shell-utils.nix`, `cloud-tools.nix`)
- Documentation: `UPPER-KEBAB-CASE.md` (e.g., `VM-SETUP.md`)
- VM variants: `<hostname>-vm/` suffix with matching configuration
