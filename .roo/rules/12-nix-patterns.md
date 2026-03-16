# Nix Patterns & Module System

## Common Configuration Patterns

### Package Installation

```nix
# NixOS system-wide
environment.systemPackages = with pkgs; [ vim git curl ];

# Home Manager user-level
home.packages = with pkgs; [ ripgrep fd bat ];
```

### Service Enable

```nix
services.<svc>.enable = true;
# + required options for the service
```

**Rule**: Always include `enable = true;` explicitly when toggling features. Do not rely on implicit defaults.

### Conditional Configuration

```nix
services.foo = lib.mkIf cfg.enable {
  # configuration applied only when condition is true
};
```

### Merged Configuration

```nix
config = lib.mkMerge [
  { /* base config */ }
  (lib.mkIf condition { /* conditional config */ })
];
```

### Overridable Defaults

```nix
services.foo.port = lib.mkDefault 8080;
# downstream modules can override without lib.mkForce
```

### Feature Toggle Pattern (used in this repo)

```nix
# home/dan/<host>.nix — compose features per host
{ ... }:
{
  imports = [
    ./global/default.nix
    ./features/cli/git.nix
    ./features/cli/zsh.nix
    ./features/development/jdk.nix
    ./features/productivity/vscode.nix
    # platform-specific
    ./features/linux/hyprland.nix
  ];

  home.username = "dan";
  home.homeDirectory = "/home/dan";
}
```

## Overlay Patterns

### Basic Overlay

```nix
# overlays/<name>/default.nix
final: prev: {
  my-package = prev.my-package.override {
    someFlag = true;
  };
}
```

### Overlay Aggregation (this repo)

```nix
# overlays/default.nix
final: prev:
let
  vscodeExts = import ./vscode-extensions final prev;
in
  vscodeExts // {
    # additional overrides
  }
```

### Applying Overlays

```nix
nixpkgs.overlays = [
  outputs.overlays.default
  nur.overlays.default
];
```

## Module System Patterns

### Custom Module with Options

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.my.module;
in
{
  options.my.module = {
    enable = mkEnableOption "my module";
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };
  };

  config = mkIf cfg.enable {
    # implementation using cfg.port
  };
}
```

### Module Import Chain

- `flake.nix` → `hosts/<host>/default.nix` → imports service modules
- `flake.nix` → `home/dan/<host>.nix` → imports `global/` + `features/`
- Never circular imports; tree structure only

## Flake Patterns

### Input Declaration

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### NixOS Configuration Output

```nix
nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
  system = "<arch>";
  specialArgs = { inherit inputs outputs; };
  modules = [
    ./hosts/<host>/default.nix
    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.dan = import ./home/dan/<host>.nix;
      home-manager.extraSpecialArgs = { inherit inputs outputs; };
    }
  ];
};
```

### Input Follows Pattern

```nix
# Pin transitive inputs to avoid duplicate nixpkgs
sops-nix.inputs.nixpkgs.follows = "nixpkgs";
disko.inputs.nixpkgs.follows = "nixpkgs";
```

## Networking Patterns

- Set `networking.hostName`
- Choose one: `networking.networkmanager.enable = true;` OR `systemd.network.enable = true;`
- Firewall: `networking.firewall.enable = true;` + `allowedTCPPorts` / `allowedUDPPorts`
- WireGuard: interface module; keep keys in SOPS secrets
- SSH: `services.openssh.enable = true;` + restrict root login + `authorizedKeys`

## Cross-Platform Patterns

### Platform Detection

```nix
# In Nix expressions
pkgs.stdenv.isDarwin  # true on macOS
pkgs.stdenv.isLinux   # true on Linux
```

### Platform Separation (this repo)

- `home/dan/features/linux/` — NixOS-only features (Hyprland, fonts, impermanence)
- `home/dan/features/macos/` — macOS-only features (system defaults)
- `home/dan/features/cli/`, `features/development/`, `features/productivity/` — cross-platform
- Host profiles handle platform-specific feature selection

### NixOS vs nix-darwin Differences

- NixOS: `services.*` uses systemd units
- nix-darwin: `services.*` uses LaunchAgents/LaunchDaemons
- Home Manager: portable across both; avoid Linux-only options on macOS
- Avoid shell `uname` checks; use Nix-native platform flags

## Option Namespace Reference

### NixOS Options

- `services.<name>.*` — System services (systemd units)
- `programs.<name>.*` — System-wide program configuration
- `networking.*` — Network configuration, firewall, interfaces
- `hardware.*` — Hardware-specific settings, drivers
- `boot.*` — Bootloader, kernel, initrd
- `security.*` — Security policies, sudo, PAM
- `users.*` — User and group management
- `environment.*` — System environment, packages, variables
- `systemd.*` — Direct systemd unit configuration

### Home Manager Options

- `home.packages` — User-level packages
- `programs.<name>.*` — User program configuration
- `services.<name>.*` — User services (systemd user units)
- `xdg.*` — XDG directories, config files, desktop entries
- `home.file.*` — Arbitrary file management in home directory
- `home.sessionVariables` — Environment variables

### Flake References

```nix
# Reference a package from a flake input
nixpkgs#<package>          # e.g., nixpkgs#vim
inputs.nixpkgs-unstable#<package>
```

## Nix Package Operations

### Search

```bash
nix search nixpkgs <term>
```

### Version Check

```bash
nix eval .#nixosConfigurations.<host>.pkgs.<name>.version
```

### Inspect Derivation

```bash
nix show-derivation $(nix build .#packages.<system>.<name> --print-out-paths)
```

### Closure Size

```bash
nix path-info -rs .#<target>
```

### Attribute Inspection

```bash
nix repl
:lf .
# then navigate attributes
```
