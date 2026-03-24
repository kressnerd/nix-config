This document provides a unified overview of the structure, modularity,
and layering of the Nix configuration repository.

# Overview

The repository is organized for modularity, maintainability, and
scalability. It uses a layered approach:

- **Flake-based entry point** for reproducible builds and input management
- **Shared NixOS base** via `hosts/common/` for deduplication
- **System-level configuration** with nix-darwin and Homebrew
- **User-level configuration** with Home Manager and feature modules
- **Secrets management** with SOPS and age

# Repository Layout

```
flake.nix
├── overlays/default.nix          (custom nixpkgs overlays)
├── lib/helpers.nix               (mkPkgsUnstable, mkFirefoxExtensions)
├── pkgs/default.nix              (custom packages — placeholder)
├── modules/nixos/                (reusable NixOS modules — placeholder)
├── modules/home-manager/         (reusable HM modules — placeholder)
├── templates/host/               (new host scaffold)
│
├── hosts/common/
│   ├── global/default.nix        (shared NixOS base: timezone, locale, NetworkManager)
│   ├── global/nix.nix            (shared Nix settings: experimental-features)
│   ├── optional/virtualisation.nix (libvirtd, virt-manager)
│   ├── optional/docker.nix       (placeholder)
│   └── users/dan.nix             (shared NixOS user definition)
│
├── hosts/J6G6Y9JK7L/             (aarch64-darwin, nix-darwin — does NOT use hosts/common/)
├── hosts/thiniel/                (x86_64-linux NixOS, imports common/global + optional/virtualisation)
└── hosts/nixos-vm-minimal/       (aarch64-linux NixOS, imports common/global)
│
├── home/dan/global/default.nix   (HM base: stateVersion, htop, ripgrep, home-manager)
├── home/dan/dotfiles/doom.d/     (Doom Emacs config — symlinked to ~/.config/doom)
└── home/dan/features/            (composable HM feature modules)
```

# Flake Outputs

| Output | Description |
|---|---|
| `darwinConfigurations.J6G6Y9JK7L` | macOS workstation |
| `nixosConfigurations.thiniel` | ThinkPad X270 |
| `nixosConfigurations.nixos-vm-minimal` | Minimal aarch64 VM |
| `overlays.default` | Custom nixpkgs overlay (vscode-extensions) |
| `templates.host` | New NixOS host scaffold |

# System and Host Layer

Each host has a directory under `hosts/` with system-level configuration.
NixOS hosts import `../common/global` for shared settings and
`../common/users/dan.nix` for the base user definition.

**J6G6Y9JK7L** (macOS/nix-darwin) does NOT import `hosts/common/` — it is
a darwin host and uses darwin-specific modules only.

# User and Feature Layer

User configuration lives under `home/dan/`. Each host has a corresponding
`home/dan/<hostname>.nix` that imports:

- `global/default.nix` — shared HM base
- Feature modules from `features/`
- Host-specific overrides (SOPS secrets, aliases, platform settings)

Doom Emacs dotfiles live at `home/dan/dotfiles/doom.d/` and are symlinked
to `~/.config/doom` via `xdg.configFile."doom"` in `emacs-doom.nix`.

# Architectural Patterns

- **Layered composition**: System (hosts/common) → Host → User (HM global) → Features
- **Shared base extraction**: Common NixOS settings in `hosts/common/` avoid duplication
- **Optional modules**: `hosts/common/optional/` for conditional system features
- **Declarative management**: All configuration is code, no imperative commands
- **Extensible modules**: New features added without disrupting existing configs

# Adding a New Host

1. Copy `templates/host/default.nix` to `hosts/<hostname>/default.nix`
2. Add `hosts/<hostname>/hardware.nix` (or generate with `nixos-generate-config`)
3. Create `home/dan/<hostname>.nix` importing global + desired feature modules
4. Register in `flake.nix` under `nixosConfigurations`

# Future Evolution

- `modules/nixos/` and `modules/home-manager/` for reusable modules
- `pkgs/` for custom derivations (scripts migration from `scripts/`)
- Additional `hosts/common/optional/` modules as needs arise
