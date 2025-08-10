# Overview

This guide covers the complete setup of Emacs on macOS using Nix Darwin
and Home Manager, including troubleshooting common issues.

# Installation Steps

## 1. Apply the Configuration

After adding the emacs.nix module to your configuration, rebuild your
system:

``` bash
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
```

## 2. First-Time Setup

After the initial installation, perform these one-time setup steps:

### Install Icon Fonts

Launch Emacs and run the following command to install icon fonts:

``` elisp
M-x all-the-icons-install-fonts
```

This ensures proper icon display in the modeline and file browser.

### Verify Daemon Setup

Check if the Emacs daemon is running:

``` bash
# Check if daemon is running
ps aux | grep emacs

# Test emacsclient
emacsclient -c
```

# Configuration Features

## Core Features Included

- **Latest Emacs 30** from nixpkgs-unstable

- **Comprehensive package set** for productivity and development

- **Nix ecosystem integration** with nix-mode, nixos-options, and LSP
  support

- **macOS optimization** with proper PATH inheritance and keybindings

- **Daemon service** for instant startup

- **Modern UI** with Doom themes and modeline

## Key Packages

|  |  |
|----|----|
| Category | Packages |
| **Core Framework** | use-package, company, ivy/counsel/swiper |
| **Nix Support** | nix-mode, nixos-options, company-nixos-options, nixd |
| **Development** | lsp-mode, lsp-ui, flycheck, yasnippet, magit |
| **UI/Themes** | doom-themes, doom-modeline, all-the-icons |
| **File Management** | projectile, treemacs, dired-sidebar |
| **macOS Integration** | exec-path-from-shell |

## Shell Integration

The configuration provides these convenient aliases:

``` bash
e filename      # Edit file (non-blocking)
ec              # New Emacs frame
et              # Terminal mode
emacs-restart   # Restart daemon
```

# Troubleshooting Guide

## Common Issues and Solutions

### 1. Font Rendering Issues

**Problem:** Fonts look incorrect or inconsistent.

**Solutions:**

``` bash
# The configuration already includes NerdFonts
# If you need additional fonts, rebuild after adding them
```

**Emacs font configuration:**

``` elisp
;; Add to your init file for custom fonts
(set-face-attribute 'default nil
                    :family "JetBrains Mono"
                    :height 140
                    :weight 'medium)
```

### 2. PATH Integration Issues

**Problem:** Emacs can’t find system tools or has incorrect PATH.

**Solutions:**

``` elisp
;; Already included in configuration - exec-path-from-shell
;; If issues persist, manually check:
M-x getenv RET PATH

;; To debug PATH issues:
M-x shell-command RET echo $PATH
```

**Alternative solution:**

``` bash
# Add to your shell profile
export PATH="/run/current-system/sw/bin:$PATH"
```

### 3. GUI Application Launch Issues

**Problem:** Emacs doesn’t appear in Spotlight or Application folder.

**Solutions:**

``` bash
# Rebuild and reset Launch Services
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

**Manual app creation:**

``` bash
# Create app alias (if needed)
ln -s /run/current-system/sw/Applications/Emacs.app ~/Applications/
```

### 4. Daemon Service Issues

**Problem:** Emacs daemon not starting automatically.

**Solutions:**

``` bash
# Check service status
launchctl list | grep emacs

# Manually start daemon
emacs --daemon

# Restart daemon
pkill -f emacs
emacs --daemon
```

**Force daemon restart:**

``` bash
# Use the provided alias
emacs-restart
```

### 5. Package Loading Errors

**Problem:** Emacs packages fail to load or compile.

**Solutions:**

``` elisp
;; Clear package compilation cache
M-x byte-recompile-directory RET ~/.emacs.d RET

;; Or start with clean config
emacs -Q
```

**Nix-specific solution:**

``` bash
# Rebuild with clean package cache
nix-collect-garbage -d
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
```

### 6. LSP Server Issues

**Problem:** Language servers not working correctly.

**Solutions:**

``` elisp
;; Check LSP server status
M-x lsp-doctor

;; Restart LSP server
M-x lsp-restart-workspace
```

**For Nix files specifically:**

``` bash
# Ensure nixd is available
which nixd

# Check nixd configuration
nixd --help
```

## macOS-Specific Issues

### Window Management

**Problem:** Emacs windows behave differently than other macOS apps.

**Solution:**

``` elisp
;; Add to configuration for better macOS integration
(setq ns-use-native-fullscreen t
      ns-use-fullscreen-animation t
      mac-allow-anti-aliasing t)
```

### Keyboard Shortcuts

**Problem:** Keyboard shortcuts conflict with system shortcuts.

**Solution:** The configuration sets up proper macOS key bindings: -
`Option` → `Meta` - `Command` → `Super` - Right `Option` → `nil` (for
international characters)

# Performance Optimization

## Startup Performance

The daemon service provides instant startup, but you can optimize
further:

``` elisp
;; Add to configuration for faster startup
(setq gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024))

;; Reset after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 800000)))
```

## Memory Usage

``` elisp
;; Monitor memory usage
M-x memory-report

;; Clear unnecessary buffers
M-x clean-buffer-list
```

# Usage Tips

## Essential Keybindings

|                     |                            |
|---------------------|----------------------------|
| Binding             | Function                   |
| `C-x g`             | Open Magit (Git interface) |
| `C-c p`             | Projectile commands        |
| `C-s`               | Swiper search              |
| `M-x counsel-`      | Various Counsel commands   |
| `C-c l`             | LSP commands               |
| `s-=`, `s--`, `s-0` | Text scaling (macOS)       |

## Nix-Specific Commands

``` elisp
;; Browse NixOS options
M-x nixos-options

;; Format Nix code
M-x nix-format-buffer

;; LSP actions in Nix files
M-x lsp-execute-code-action
```

# Advanced Configuration

## Custom Package Management

If you need additional packages not in the base configuration:

``` nix
# Add to extraPackages in emacs.nix
extraPackages = epkgs: with epkgs; [
  # Your additional packages here
  pdf-tools
  org-noter
  helm  # Alternative to ivy
];
```

## Custom Configuration

Add custom Elisp to the `extraConfig` section:

``` nix
extraConfig = ''
  ;; Your custom configuration
  (setq custom-variable value)

  ;; Custom keybindings
  (global-set-key (kbd "C-c C-c") 'custom-function)
'';
```

# Getting Help

## Built-in Help

``` elisp
C-h ?           # Help menu
C-h k <key>     # Describe key
C-h f <func>    # Describe function
C-h v <var>     # Describe variable
C-h m           # Current mode help
```

## Community Resources

- [Emacs Stack Exchange](https://emacs.stackexchange.com/)

- [r/emacs subreddit](https://www.reddit.com/r/emacs/)

- [Home Manager
  documentation](https://github.com/nix-community/home-manager)

- [Nixpkgs Emacs
  documentation](https://nixos.org/manual/nixpkgs/stable/#sec-emacs)

# Conclusion

This configuration provides a robust, modern Emacs setup optimized for
macOS and Nix development. The declarative approach ensures
reproducibility across different systems while maintaining the
flexibility that makes Emacs powerful.

Remember to restart the daemon after making configuration changes and
rebuild your system to apply Nix-level modifications.
