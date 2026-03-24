# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Apply Commands

**macOS (nix-darwin) — primary development host `J6G6Y9JK7L`:**
```bash
# Build without activating (dry-run test)
darwin-rebuild build --flake .#J6G6Y9JK7L

# Apply changes (or use the `drs` fish alias)
sudo darwin-rebuild switch --flake .#J6G6Y9JK7L

# Debug build failures
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace

# Rollback
darwin-rebuild --list-generations
sudo darwin-rebuild rollback
```

**NixOS:**
```bash
sudo nixos-rebuild switch --flake .#<hostname>   # e.g. thiniel, pronix, cupix001
```

**Flake validation:**
```bash
nix flake check    # Validate all outputs
nix flake show     # List all configurations
nix flake update   # Update all inputs (updates flake.lock)
```

**Nix formatting:**
```bash
alejandra .        # Format all Nix files (primary formatter)
```

**VM deployment** (from repo root):
```bash
scripts/build-vm-test.sh pronix-vm|cupix001-vm   # Build VM test images
scripts/deploy-vm.sh deploy <host> <ip>           # Deploy via nixos-anywhere
```

## Architecture

Layered, composable Nix configuration for macOS (nix-darwin) and NixOS. Channels: `nixpkgs-25.11` (stable), `nixpkgs-unstable`.

```
flake.nix
├── darwinConfigurations.J6G6Y9JK7L  →  hosts/J6G6Y9JK7L/     (nix-darwin system)
│                                    →  home/dan/J6G6Y9JK7L.nix (home-manager)
├── nixosConfigurations.<host>       →  hosts/<host>/           (NixOS system)
│   (NixOS only)                        imports ../common/global + ../common/users/dan.nix
│                                    →  home/dan/<host>.nix     (home-manager)
│
├── hosts/common/global/default.nix  (shared NixOS base: timezone, locale, NetworkManager)
├── hosts/common/global/nix.nix      (shared Nix settings: experimental-features)
├── hosts/common/optional/           (optional NixOS modules: virtualisation, docker)
├── hosts/common/users/dan.nix       (shared NixOS user base definition)
│
├── home/dan/global/default.nix      (HM base: htop, ripgrep, home-manager self-management)
├── home/dan/dotfiles/doom.d/        (Doom Emacs config — symlinked to ~/.config/doom)
├── home/dan/features/<category>/<tool>.nix  (composable feature modules)
│
├── lib/helpers.nix                  (mkPkgsUnstable, mkFirefoxExtensions)
├── overlays/default.nix             (custom nixpkgs overlay aggregator)
├── pkgs/default.nix                 (custom packages — placeholder)
├── modules/nixos/                   (reusable NixOS modules — placeholder)
├── modules/home-manager/            (reusable HM modules — placeholder)
└── templates/host/                  (new NixOS host scaffold)
```

### Host Definitions

| Hostname | System | Type | Key Features |
|---|---|---|---|
| `J6G6Y9JK7L` | aarch64-darwin | Primary macOS workstation | Homebrew casks, Fish shell, Doom Emacs, multi-identity Git via SOPS, containers |
| `thiniel` | x86_64-linux | Physical NixOS (ThinkPad X270) | Hyprland, impermanence (btrfs root wipe), libvirtd |
| `pronix` | x86_64-linux | Physical NixOS server | Dual NVMe RAID1, LUKS, LVM, impermanence, initrd SSH unlock |
| `cupix001` | x86_64-linux | Production VPS (Netcup) | Headscale, Nginx, fail2ban, ACME/Let's Encrypt, AppArmor, impermanence |
| `*-vm` variants | varies | Test VMs | Simplified versions of above: single virtio disk, password auth, no hardening |
| `nixos-vm-minimal` | aarch64-linux | Minimal test VM | Bare minimum for NixOS testing |

### Username Convention
- **macOS**: `daniel.kressner` (home: `/Users/daniel.kressner`)
- **NixOS**: `dan` (home: `/home/dan`)

### Feature Modules (`home/dan/features/`)

| Category | Modules |
|---|---|
| `cli/` | cloud-tools, fish, git, kitty, shell-utils, ssh, starship, vim, zsh |
| `development/` | containers (5 submodules), fnm, formatters, jdk, nodejs |
| `productivity/` | browser, emacs-doom, emacs, firefox-company, firefox-personal, keepassxc, mac-tools, owncloud, sweethome3d, vscode |
| `macos/` | defaults (system preferences automation via `targets.darwin`) |
| `linux/` | fonts, hyprland, impermanence |

## Key Patterns

### Adding a New Feature
1. Create `home/dan/features/<category>/<tool>.nix`
2. Import it in `home/dan/<hostname>.nix`
3. Apply with `drs` (macOS) or `sudo nixos-rebuild switch` (NixOS)

### Feature Module Structure
```nix
{ config, pkgs, lib, ... }: {
  home.packages = [ pkgs.sometool ];
  programs.sometool = { enable = true; ... };
  # optionally: sops.templates, home.file, home.activation, services, etc.
}
```

### Unstable Packages
Available via `pkgs-unstable` passed through `extraSpecialArgs` in `flake.nix`. Use in module arguments:
```nix
{ pkgs-unstable, ... }: {
  home.packages = [ pkgs-unstable.sometool ];
}
```

### Platform-Conditional Logic
```nix
# OS-specific values
if pkgs.stdenv.isDarwin then "macOS-value" else "linux-value"

# Conditional package lists
home.packages = with pkgs; [ common-pkg ]
  ++ lib.optionals pkgs.stdenv.isDarwin [ mac-only-pkg ]
  ++ lib.optionals pkgs.stdenv.isLinux [ linux-only-pkg ];
```
Used in: kitty.nix (window decorations), emacs-doom.nix (packages, daemon config), browser.nix (Firefox package).

### SOPS Secrets Flow
Secrets are age-encrypted YAML files decrypted at activation time:
1. **Declare** secrets in host `.nix` file under `sops.secrets` (references `hosts/<host>/secrets.yaml`)
2. **Consume** in feature modules via `config.sops.placeholder."path/to/secret"` inside `sops.templates`
3. **Guard optional** secrets with `lib.optionalAttrs (config.sops.secrets ? "key") { ... }`

Example from git.nix — multi-identity git config:
```nix
sops.templates.".gitconfig".content = ''
  [include]
    path = ${config.sops.templates.".gitconfig-personal".path}
'' + lib.optionalString (config.sops.secrets ? "git/company/name") ''
  [includeIf "gitdir:${config.sops.placeholder."git/company/folder"}"]
    path = ${config.sops.templates.".gitconfig-company".path}
'';
```

### Home Manager Activation DAG
For custom setup scripts (e.g., Doom Emacs install, directory creation):
```nix
home.activation.scriptName = lib.hm.dag.entryAfter ["writeBoundary"] ''
  # script runs after files are written
'';
```

### Homebrew (macOS Only)
Managed declaratively in `hosts/J6G6Y9JK7L/default.nix` via `nix-homebrew`. Prefer Nix packages; Homebrew only for:
- **Casks** (GUI apps): kitty, claude, claude-code, crossover, cameracontroller
- **Brews** requiring signed binaries: score-compose

Kitty override pattern — HM generates config, Homebrew provides the app:
```nix
programs.kitty.package = pkgs.emptyDirectory;  # in J6G6Y9JK7L.nix
```

### Container Module Architecture
`features/development/containers.nix` is an orchestrator importing 4 submodules:
- `containers-common.nix` — shared packages (podman, kubectl, k9s, dive, etc.), aliases (`docker` → `podman`), directory structure
- `containers-podman.nix` — Podman config files (containers.conf, storage.conf, registries.conf)
- `containers-vscode.nix` — VS Code devcontainer integration with Podman, project templates
- `containers-nix-tools.nix` — Nix-based container builds, k8s deployment helpers
- `containers-networking.nix` — Network configs (dev: 10.89.0.0/16, isolated: 10.90.0.0/16), volume strategies

### Firefox Extension Library
Shared extension sets defined in `lib/helpers.nix` via `mkFirefoxExtensions`, imported by profile modules:
```nix
let exts = (import ../../../../lib/helpers.nix).mkFirefoxExtensions { inherit addons; };
in { extensions = exts.common ++ exts.privacy ++ exts.dev; }
```
Categories: common, dev, privacy, productivity, convenience.

### Overlays
`overlays/default.nix` aggregates custom overlays. Currently: `vscode-extensions/` (Roo Cline extension via `buildVscodeMarketplaceExtension`). Applied globally in `flake.nix` via `nixpkgs.overlays`.

### Impermanence Pattern (NixOS Hosts)
Used on thiniel, pronix, cupix001. Root filesystem is wiped on boot via btrfs subvolume reset. Persistent state is mounted from `/persist`. Feature module at `features/linux/impermanence.nix` defines user-level persistent directories (.ssh, .mozilla, dev, Projects, etc.).

## Secrets Setup

**Age key locations:**
- macOS: `~/Library/Application Support/sops/age/keys.txt`
- NixOS (impermanence): `/persist/system/var/lib/sops-nix/key.txt`
- VPS (cupix001): `/persist/var/lib/sops-nix/key.txt`

**`.sops.yaml`** at repo root maps age keys to secret files:
- `hosts/J6G6Y9JK7L/secrets.yaml` → macOS age key (multi-identity git config)
- `hosts/thiniel/secrets.yaml` → Linux age key (personal git, user passwords)

## Utility Files

- **`lib/helpers.nix`** — `mkPkgsUnstable` (creates unstable nixpkgs instance) and `mkFirefoxExtensions` (categorized addon sets)
- **`shell.nix`** — Dev shell with nix, home-manager, git (+ commented sops/age tools)
- **`scripts/`** — VM build (`build-vm.sh`, `build-vm-test.sh`) and deploy (`deploy-vm.sh`) scripts for UTM/nixos-anywhere. See `scripts/README.md`.

## Documentation

Detailed guides in `docs/`:
- `ARCHITECTURE.md` — module layering details
- `HOME-MANAGER.md` — feature module patterns and examples
- `DEVELOPMENT.md` — workflow, secrets management, testing strategy
- `CUPIX001-DEPLOYMENT.md` — VPS bastion host deployment
- `NIXOS-ANYWHERE-SETUP.md` / `VM-SETUP.md` / `VM-TESTING-GUIDE.md` — VM deployment
- `DOOM-EMACS-SETUP-GUIDE.md` — Emacs/LSP setup (Nix manages binary + tools, Doom manages Lisp packages)
- `EDGE-INGRESS-GATEWAY.md` — VPS edge ingress gateway design (German)
