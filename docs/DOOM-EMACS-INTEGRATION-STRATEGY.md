# Doom Emacs Integration Strategy

## Overview

This document outlines the integration strategy for adding Doom Emacs to the existing Nix configuration while preserving the current Emacs v30.1 setup.

## Integration Approaches

### Approach 1: Full Declarative Integration (Recommended)

**Strategy**: Replace existing Emacs configuration with nix-doom-emacs-unstraightened

**Benefits**:

- Complete reproducibility
- Integrated package management
- Eliminates configuration drift
- Full Home Manager integration

**Implementation**:

1. **Flake Input Addition**:

```nix
# In flake.nix inputs section
nix-doom-emacs-unstraightened = {
  url = "github:marienz/nix-doom-emacs-unstraightened";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. **Home Manager Module Integration**:

```nix
# In home-manager sharedModules
sharedModules = [
  mac-app-util.homeManagerModules.default
  sops-nix.homeManagerModules.sops
  inputs.nix-doom-emacs-unstraightened.homeModule
];
```

3. **Configuration Replacement**:

```nix
# Replace programs.emacs with programs.doom-emacs
programs.doom-emacs = {
  enable = true;
  doomDir = ./doom.d;  # Local Doom configuration
  provideEmacs = true; # Provides both doom-emacs and emacs binaries
};
```

### Approach 2: Side-by-Side Installation (Conservative)

**Strategy**: Install Doom Emacs alongside existing Emacs setup

**Benefits**:

- No disruption to current workflow
- Easy comparison and migration
- Fallback to vanilla Emacs available

**Implementation**:

```nix
# Keep existing programs.emacs configuration
programs.emacs = {
  enable = true;
  package = pkgs.emacs;
  # ... existing configuration
};

# Add Doom Emacs as separate program
programs.doom-emacs = {
  enable = true;
  doomDir = ./doom.d;
  provideEmacs = false;  # Only provides doom-emacs binary
};
```

### Approach 3: Hybrid Configuration (Fallback)

**Strategy**: Traditional Doom installation with Nix-managed dependencies

**Benefits**:

- More flexible configuration
- Upstream compatibility
- Live configuration editing

**Implementation**:

```nix
# Enhanced base Emacs with Doom-compatible packages
programs.emacs = {
  enable = true;
  package = pkgs.emacs;
  extraPackages = epkgs: with epkgs; [
    # Doom core dependencies
    doom-themes
    doom-modeline
    all-the-icons
    # ... other packages
  ];
};

# Add Doom installation script
home.packages = with pkgs; [
  git
  ripgrep
  fd
  # Other Doom dependencies
];
```

## Recommended Implementation Plan

### Phase 1: Preparation and Testing

1. **Create Doom Configuration Directory**:

```bash
mkdir -p home/dan/doom.d
```

2. **Basic Doom Configuration**:

```elisp
;; doom.d/init.el - Module selection
(doom! :input
       :completion
       (ivy +prescient)

       :ui
       doom
       doom-dashboard
       doom-quit
       modeline
       ophints
       (popup +defaults)
       treemacs
       vc-gutter
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       (format +onsave)
       multiple-cursors
       snippets

       :emacs
       dired
       electric
       ibuffer
       undo
       vc

       :term
       vterm

       :checkers
       syntax
       (spell +flyspell)
       grammar

       :tools
       (eval +overlay)
       lookup
       lsp
       magit
       make
       pdf

       :os
       (:if IS-MAC macos)

       :lang
       emacs-lisp
       (org +roam2)
       nix
       markdown
       json
       yaml
       web

       :config
       (default +bindings +smartparens))
```

3. **Doom Package Configuration**:

```elisp
;; doom.d/packages.el - Additional packages
(package! company-nixos-options)
(package! nixos-options)
```

4. **Doom Custom Configuration**:

```elisp
;; doom.d/config.el - Personal configuration
(setq user-full-name "Daniel Kressner"
      user-mail-address "your-email@example.com")

;; macOS specific settings
(when IS-MAC
  (setq mac-option-modifier 'meta
        mac-command-modifier 'super
        mac-right-option-modifier 'nil))

;; Font configuration
(setq doom-font (font-spec :family "SF Mono" :size 14 :weight 'medium))

;; Theme
(setq doom-theme 'doom-one)

;; Nix-specific configuration
(after! nix-mode
  (add-to-list 'company-backends 'company-nixos-options))
```

### Phase 2: Flake Integration

1. **Update flake.nix**:

```nix
{
  description = "Dan's nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Add Doom Emacs integration
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ... other inputs
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-doom-emacs-unstraightened, ... } @ inputs:
  let
    inherit (self) outputs;
  in {
    darwinConfigurations = {
      J6G6Y9JK7L = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs outputs; };
        modules = [
          # ... existing modules
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              # ... existing config
              sharedModules = [
                mac-app-util.homeManagerModules.default
                sops-nix.homeManagerModules.sops
                inputs.nix-doom-emacs-unstraightened.homeModule
              ];
            };
          }
        ];
      };
    };
  };
}
```

### Phase 3: Emacs Configuration Migration

**Option A: Replace existing configuration**:

```nix
# home/dan/features/productivity/emacs.nix
{ config, pkgs, lib, ... }: {
  # Replace programs.emacs with programs.doom-emacs
  programs.doom-emacs = {
    enable = true;
    doomDir = ./../../doom.d;  # Point to doom configuration
    provideEmacs = true;       # Provides both binaries
  };

  # Keep existing services.emacs configuration
  services.emacs = {
    enable = true;
    defaultEditor = true;
    client.enable = true;
    startWithUserSession = "graphical";
  };

  # Keep existing packages and shell configuration
  home.packages = with pkgs; [
    nixd
    nodePackages.typescript-language-server
    pyright
    rust-analyzer
    silver-searcher
    git-crypt
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  programs.zsh = {
    shellAliases = {
      e = "emacsclient -n";
      ec = "emacsclient -c";
      et = "emacsclient -t";
      emacs-restart = "pkill -f emacs; emacs --daemon";
    };
    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -c";
    };
  };

  # Keep macOS integration
  targets.darwin.defaults = lib.mkIf pkgs.stdenv.isDarwin {
    "com.apple.LaunchServices" = {
      LSHandlers = [
        {
          LSHandlerContentType = "public.plain-text";
          LSHandlerRoleAll = "org.gnu.Emacs";
        }
      ];
    };
  };
}
```

**Option B: Side-by-side installation**:

```nix
# home/dan/features/productivity/emacs.nix
{ config, pkgs, lib, ... }: {
  # Keep existing Emacs configuration
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    # ... existing config
  };

  # Add Doom Emacs alongside
  programs.doom-emacs = {
    enable = true;
    doomDir = ./../../doom.d;
    provideEmacs = false;  # Only doom-emacs binary
  };

  # Services still use regular emacs
  services.emacs = {
    enable = true;
    package = pkgs.emacs;  # Explicit vanilla emacs
    # ... rest of config
  };

  # Add alias for doom
  programs.zsh.shellAliases = {
    doom = "doom-emacs";
    de = "doom-emacs";
    # ... existing aliases
  };
}
```

## Migration and Rollback Strategy

### Migration Steps

1. **Backup Current Configuration**:

```bash
tar -czf ~/.emacs.d-backup-$(date +%Y%m%d).tar.gz ~/.emacs.d
```

2. **Test Doom Configuration**:

```bash
nix run github:marienz/nix-doom-emacs-unstraightened -- --config /path/to/doom.d
```

3. **Apply Configuration**:

```bash
darwin-rebuild switch --flake .
```

### Rollback Procedures

1. **Quick Rollback**:

```bash
darwin-rebuild switch --rollback
```

2. **Configuration Rollback**:

   - Revert `flake.nix` changes
   - Restore `emacs.nix` from git
   - Switch configuration

3. **Emergency Fallback**:

```bash
# Disable Doom, enable vanilla Emacs
programs.doom-emacs.enable = false;
programs.emacs.enable = true;
```

## Maintenance Procedures

### Updates

1. **Doom and Dependencies**:

```bash
nix flake update nix-doom-emacs-unstraightened
darwin-rebuild switch --flake .
```

2. **Configuration Changes**:
   - Edit files in `doom.d/`
   - Commit changes to git
   - Rebuild: `darwin-rebuild switch --flake .`

### Monitoring

1. **Check Doom Health**:

```bash
doom doctor
```

2. **Verify Package Integrity**:

```bash
doom sync --check
```

## Conclusion

The recommended approach is **Full Declarative Integration** using nix-doom-emacs-unstraightened, as it provides the best balance of reproducibility and functionality while maintaining the declarative principles of the existing Nix configuration.

The side-by-side approach serves as a conservative fallback for users who want to evaluate Doom Emacs without disrupting their current workflow.
