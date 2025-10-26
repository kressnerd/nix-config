# Doom Emacs Setup Guide

## Overview

This configuration implements **Henrik Lissner's recommended approach** for integrating Doom Emacs with Nix and Home Manager. This approach provides a clean separation of concerns:

- **Nix manages**: Emacs binary and external system tools (LSP servers, formatters, etc.)
- **Doom Emacs manages**: All Emacs Lisp packages via straight.el

This separation avoids the complexity and conflicts that arise from trying to manage Emacs packages declaratively through Nix.

## Philosophy

Henrik Lissner's approach (from his [dotfiles](https://github.com/hlissner/dotfiles)) treats Doom Emacs as a **self-contained package management system**:

1. Nix provides system-level stability (Emacs binary, fonts, LSP servers)
2. Doom's straight.el provides Emacs package flexibility and disaster recovery
3. No overlap between the two systems - each manages its own domain

**Why this approach?**

- Emacs package ecosystem is highly dynamic and frequently breaks
- Straight.el provides better disaster recovery than Nix for Emacs packages
- Simpler to maintain - follows Doom's standard workflow
- Better compatibility with upstream Doom documentation

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│ Nix/Home Manager Layer                                       │
│ • Emacs 30.1 binary                                          │
│ • System tools (ripgrep, fd, git)                           │
│ • LSP servers (nixd, pyright, rust-analyzer)                │
│ • Formatters (nixpkgs-fmt, black, prettier)                 │
│ • Fonts (JetBrains Mono, Fira Code)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Doom Emacs Layer (straight.el)                              │
│ • All Emacs Lisp packages                                   │
│ • Doom modules and their dependencies                       │
│ • Third-party packages from MELPA/ELPA                      │
│ • Custom configurations                                      │
└─────────────────────────────────────────────────────────────┘
```

### File Structure

```
~/.config/
├── emacs/              # Doom Emacs installation (managed by straight.el)
│   ├── bin/doom        # Doom CLI tool
│   └── ...
├── doom/               # Symlink to our managed doom.d
│   ├── init.el         # Module configuration
│   ├── config.el       # Personal settings
│   ├── packages.el     # Package declarations
│   └── local.el        # Machine-specific config (optional)
└── nix-config/
    └── home/dan/doom.d/  # Actual doom.d (version controlled)
```

## Installation

### First-Time Setup

The configuration automatically handles Doom installation via Home Manager activation:

```bash
# For macOS
darwin-rebuild switch --flake .#J6G6Y9JK7L

# For NixOS
sudo nixos-rebuild switch --flake .#hostname
```

This will:

1. Install Emacs and system dependencies via Nix
2. Clone Doom Emacs to `~/.config/emacs`
3. Create symlink from `~/.config/doom` to your managed `doom.d`
4. Run `doom install` and `doom sync`

### Verification

After installation, verify everything is working:

```bash
# Check Doom installation
~/.config/emacs/bin/doom doctor

# Start Emacs
emacs

# Or use the daemon
emacsclient -c
```

## Configuration Management

### Modifying Doom Modules

Edit [`init.el`](../home/dan/doom.d/init.el) to enable/disable Doom modules:

```elisp
(doom! :completion
       (company +childframe)
       (ivy +prescient +fuzzy +icons)

       :lang
       nix
       (python +lsp)
       (org +roam2))
```

After changes:

```bash
doom sync
```

### Adding Packages

Add packages in [`packages.el`](../home/dan/doom.d/packages.el):

```elisp
;; From MELPA
(package! some-package)

;; From GitHub
(package! my-package
  :recipe (:host github :repo "user/repo"))
```

After changes:

```bash
doom sync
```

### Personal Configuration

Edit [`config.el`](../home/dan/doom.d/config.el) for personal settings:

```elisp
;; Customize appearance
(setq doom-theme 'doom-one
      doom-font (font-spec :family "JetBrains Mono" :size 14))

;; macOS keybindings
(when IS-MAC
  (setq mac-command-modifier 'super))
```

No sync needed - changes take effect after restarting Emacs.

## Doom Commands

### Essential Doom CLI Commands

```bash
# Update Doom and packages
doom upgrade

# Sync package state with config
doom sync

# Health check
doom doctor

# Clean build artifacts
doom clean

# Compile config for better performance
doom compile
```

### Using Doom Sync

After modifying `init.el` or `packages.el`, always run:

```bash
doom sync
```

This:

1. Installs new packages
2. Removes unused packages
3. Rebuilds autoloads
4. Recompiles config

## Package Management

### Adding Packages

**For Doom Module Packages:**

Most packages are available through Doom modules. Enable them in `init.el`:

```elisp
(doom! :lang
       (python +lsp)    ; Includes python-mode, lsp-pyright
       (org +roam2))    ; Includes org-roam v2
```

**For Individual Packages:**

Declare in `packages.el`:

```elisp
(package! restclient)
(package! org-super-agenda)
```

**For System Tools:**

Edit [`emacs-doom.nix`](../home/dan/features/productivity/emacs-doom.nix) to add LSP servers or formatters:

```nix
home.packages = with pkgs; [
  # LSP servers
  rust-analyzer

  # Formatters
  rustfmt
];
```

### Updating Packages

**Update Doom and all packages:**

```bash
doom upgrade
```

**Update specific package:**

```bash
doom sync -u package-name
```

**Rollback after bad update:**

```bash
doom rollback
```

### Removing Packages

1. Remove from `init.el` (modules) or `packages.el` (individual)
2. Run `doom sync`
3. Doom will automatically remove unused packages

## System Updates

### Updating Nix Components

Update Emacs and system tools:

```bash
# Update flake inputs
nix flake update

# Rebuild system
darwin-rebuild switch --flake .#J6G6Y9JK7L  # macOS
# or
sudo nixos-rebuild switch --flake .#hostname  # NixOS
```

### Update Workflow

Recommended update sequence:

```bash
# 1. Update Nix components
nix flake update
darwin-rebuild switch --flake .#J6G6Y9JK7L

# 2. Update Doom
doom upgrade

# 3. Verify health
doom doctor
```

## Troubleshooting

### Doom Issues

**Package not found:**

```bash
doom sync    # Refresh package list
doom clean   # Clean build artifacts
```

**Build errors:**

```bash
doom doctor              # Check for issues
doom sync -p package-name  # Reinstall specific package
```

**Performance issues:**

```bash
doom compile            # Recompile for better performance
```

### Nix Issues

**Emacs binary not found:**

```bash
# Rebuild Home Manager configuration
home-manager switch --flake .#hostname
```

**LSP server not working:**

Verify LSP server is installed:

```bash
which nixd    # Should show Nix store path
```

If missing, add to `emacs-doom.nix` and rebuild.

### Common Problems

**Problem**: Doom complains about missing packages

**Solution**: Run `doom sync` to install declared packages

---

**Problem**: LSP not working

**Solution**:

1. Check LSP server is installed via Nix: `which language-server`
2. Verify Doom LSP module is enabled in `init.el`
3. Check LSP config in `config.el`

---

**Problem**: Font not displaying correctly

**Solution**:

1. Verify font is installed: Check `emacs-doom.nix` packages
2. Rebuild system to install fonts
3. Update font config in `config.el`

---

**Problem**: Activation hook fails

**Solution**:

1. Check `~/.config/emacs` exists
2. Manually run: `~/.config/emacs/bin/doom sync`
3. Check for error messages in activation output

## Integration with Development Tools

### LSP Servers

LSP servers are managed by Nix, not Doom:

```nix
# In emacs-doom.nix
home.packages = with pkgs; [
  nixd                    # Nix
  pyright                 # Python
  rust-analyzer           # Rust
  typescript-language-server  # TypeScript
];
```

Doom automatically discovers these via PATH.

### Git Integration

Magit uses git from Nix:

```nix
home.packages = with pkgs; [
  git
  git-crypt
];
```

### Terminal Integration

Shell aliases for Emacs:

```bash
e     # emacsclient -t (terminal)
ec    # emacsclient -c (GUI)
doom  # Doom CLI
```

## Best Practices

### Workflow

1. **Small Changes**: Test one module at a time
2. **Version Control**: Commit working configs before experimenting
3. **Health Checks**: Run `doom doctor` after major changes
4. **Separation**: Never mix Nix emacsPackages with Doom packages

### Performance

1. **Lazy Loading**: Use `:defer` in package declarations
2. **Native Compilation**: Emacs 30 provides this by default
3. **Startup Optimization**: Run `doom compile` periodically
4. **Clean Builds**: Run `doom clean` when things feel slow

### Maintenance

1. **Regular Updates**: Update Doom monthly: `doom upgrade`
2. **System Updates**: Update Nix inputs monthly: `nix flake update`
3. **Health Monitoring**: Run `doom doctor` after updates
4. **Rollback Ready**: Keep working flake.lock in git

## macOS Specific

### File Associations

The configuration registers Emacs with macOS Launch Services for text files.

### Keybindings

macOS Command key is mapped to Super:

- `Cmd-=`: Increase font size
- `Cmd--`: Decrease font size
- `Cmd-0`: Reset font size

### Notifications

Terminal notifications work via `terminal-notifier` (installed via Nix).

## Advanced Topics

### Machine-Specific Configuration

Create `~/.config/doom/local.el` for machine-specific settings:

```elisp
;;; local.el --- Machine-specific configuration

;; This file is git-ignored and loaded by config.el
(setq user-mail-address "machine-specific@email.com")
```

### Custom Doom Modules

Create local modules in `~/.config/doom/modules/`:

```elisp
;; In config.el
(add-to-list 'doom-module-load-path "~/.config/doom/modules")
```

### Disaster Recovery

If Doom breaks:

```bash
# 1. Rollback Doom
doom rollback

# 2. Or reinstall from scratch
rm -rf ~/.config/emacs
darwin-rebuild switch --flake .#J6G6Y9JK7L
```

## Resources

- **Doom Emacs**: https://github.com/doomemacs/doomemacs
- **Henrik Lissner's dotfiles**: https://github.com/hlissner/dotfiles
- **Doom Discourse**: https://discourse.doomemacs.org/
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/

## Migration from nix-doom-emacs-unstraightened

If you previously used `nix-doom-emacs-unstraightened`:

1. **Backup** your current setup
2. **Remove** `~/.config/emacs` (Doom installation)
3. **Apply** this new configuration
4. **Run** `doom sync` after activation completes
5. **Verify** with `doom doctor`

The new approach is simpler and follows upstream Doom's standard workflow.
