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
nix fmt .          # Format all Nix files (uses nixfmt-rfc-style via flake formatter output)
```

**Validation pipeline:**
```bash
# Evaluation-only (fast, fires assertions, no VM tests)
nix flake check --no-build

# Full check (evaluation + all checks derivations)
nix flake check

# Specific check
nix build .#checks.<system>.<name>

# Linting (on changed files)
deadnix --fail <file.nix>
statix check <file.nix>
nixfmt --check <file.nix>
```

**Current checks:**

| Check | Systems | Type |
|---|---|---|
| `unit-helpers` | all | Unit tests (`lib.debug.runTests`) |
| `lint-deadnix` | all | Unused Nix bindings |
| `lint-statix` | all | Nix anti-patterns |
| `lint-nixfmt` | all | Formatting (nixfmt-rfc-style) |
| `integration-vm-minimal-ssh` | Linux only | VM integration test (QEMU) |

---

## Test-First Workflow (MANDATORY)

Every configuration change MUST follow Red-Green-Refactor. Write the test first, confirm it fails (Red), implement the change, confirm it passes (Green), then clean up (Refactor).

### One Change Per Cycle

Each cycle covers exactly **one minimal, verifiable change**:
- One assertion per cycle (not 5 at once)
- One module option per cycle
- One firewall rule per cycle

| Change Scope | Expected Cycles |
|---|---|
| Add one package | 1 (assertion or unit test) |
| Enable a service | 2–3 (enable → port → security) |
| Configure firewall | 1 per rule/port |
| New feature module | 3–5 (option → enable → config → verify → refactor) |
| New host config | 5–10 (hostname → network → firewall → SSH → users → services) |

### Iterative Example

```
Cycle 1: Red   → assertion: hostname must not be empty
         Green → set networking.hostName = "myhost"

Cycle 2: Red   → assertion: firewall must be enabled
         Green → networking.firewall.enable = true

Cycle 3: Red   → nixosTest: SSH must be running
         Green → services.openssh.enable = true

Cycle 4: Red   → nixosTest: root login must be disabled
         Green → services.openssh.settings.PermitRootLogin = "no"

Cycle 5: Refactor → extract SSH config into reusable module
         Verify  → all tests still pass
```

### Test Layers

| Layer | Tool | VM? | Directory | Trigger |
|---|---|---|---|---|
| Unit | `lib.debug.runTests` | No | `tests/unit/` | Pure Nix logic (helpers, transforms) |
| Assertions | NixOS `assertions` | No (eval-time) | `tests/assertions/` | Option constraints, type guards, invariants |
| Integration | `pkgs.testers.runNixOSTest` | Yes (Linux only) | `tests/integration/` | Services, firewall, networking, systemd |
| Deploy | `pytest-testinfra` | No (SSH) | `tests/deploy/` | Post-deployment verification on live hosts |

### Red-Green-Refactor Cycle

**For module/option changes:**
1. Red: Write assertion or unit test → `nix flake check --no-build` → FAIL
2. Green: Implement option/module → `nix flake check --no-build` → PASS
3. Refactor: Clean up → `nix flake check` → PASS

**For service/infrastructure changes:**
1. Red: Write `testers.runNixOSTest` → `nix build .#checks.<linux-system>.<test>` → FAIL
2. Green: Implement service config → `nix build .#checks.<linux-system>.<test>` → PASS
3. Refactor: Clean up → all tests → PASS
4. Deploy: `nixos-rebuild switch` → `pytest` validates real system

### Test File Locations

| Test Type | Directory | Naming Convention |
|---|---|---|
| Unit | `tests/unit/` | `<module>-test.nix` |
| Assertions | `tests/assertions/` | `<scope>-invariants.nix` |
| Integration | `tests/integration/` | `<host-or-feature>-test.nix` |
| Deploy | `tests/deploy/` | `test_<host>.py` |

### Obligations

- Write the test BEFORE the implementation
- Confirm test FAILS before implementing (Red)
- Confirm test PASSES after implementing (Green)
- Run ALL existing tests after refactoring (regression check)
- Wire new tests into `flake.nix` `checks` output so `nix flake check` runs them

### Exceptions

Test-first is NOT required for:
- Documentation-only changes (`.md` files)
- `nix flake update` (dependency updates)
- SOPS secret value changes (encrypted content)
- Formatting-only changes
- `.gitignore`, `.editorconfig`, and similar tooling config

### Anti-Patterns

- Writing 10 assertions, then implementing everything at once
- Creating an entire service module, then writing tests after
- Skipping Red phase because "the test is obvious"
- Deleting or weakening existing tests to make implementation pass

---

## Safety Rules

### Immutable Values

- **NEVER** change `system.stateVersion` or `home.stateVersion` — set at install time, must not change during routine updates
- `hardware-configuration.nix` / `hardware.nix` is **READ-ONLY** — modify only when explicitly changing kernel modules, filesystems, or hardware settings

### Secrets

- **NEVER** commit plaintext secrets — use `sops-nix` with age encryption
- Secret files: `hosts/<host>/secrets.yaml`
- Reference secrets via `config.sops.placeholder."path"` inside `sops.templates`

### Dangerous Changes — Always Warn + Provide Rollback

| Area | Risk | Rollback |
|---|---|---|
| `boot.loader.*` | Reboot required; may prevent boot | `darwin-rebuild --rollback` / generation switch |
| `networking.*` | Connectivity loss | `sudo nixos-rebuild test` first |
| `fileSystems.*`, `disko` | Data loss | Backup required |
| `environment.persistence.*` (impermanence) | Paths lost on reboot | Review persist list before changing |
| `boot.kernelPackages`, `boot.kernelModules` | Boot failure | Previous generation via GRUB/systemd-boot |

---

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
