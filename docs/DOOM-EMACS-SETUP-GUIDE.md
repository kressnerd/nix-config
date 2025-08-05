# Doom Emacs Setup and Maintenance Guide

## Overview

This guide covers the setup, usage, and maintenance of the declarative Doom Emacs configuration integrated with Nix and Home Manager using `nix-doom-emacs-unstraightened`.

## Key Features

- **Fully Declarative**: All packages managed through Nix, no `package.el` or `straight.el` conflicts
- **Reproducible**: Consistent builds across systems through flake.lock pinning
- **Emacs v30.1**: Latest Emacs version with native compilation support
- **Complete Integration**: Seamless Home Manager integration with proper shell environment setup
- **macOS Optimized**: Native macOS keybindings and file associations

## Architecture

### Core Components

1. **[`flake.nix`](../flake.nix:1)**: Flake input configuration for `nix-doom-emacs-unstraightened`
2. **[`home/dan/features/productivity/emacs-doom.nix`](../home/dan/features/productivity/emacs-doom.nix:1)**: Main Home Manager module
3. **[`home/dan/doom.d/`](../home/dan/doom.d/)**: Doom configuration directory
   - **[`init.el`](../home/dan/doom.d/init.el:1)**: Module selection and feature configuration
   - **[`config.el`](../home/dan/doom.d/config.el:1)**: Personal configuration and customizations
   - **[`packages.el`](../home/dan/doom.d/packages.el:1)**: Additional package declarations

### Package Management Flow

```
Nix Store → Doom Profile → Emacs with Doom → User Environment
     ↑            ↑              ↑               ↑
nixpkgs    doom modules    emacs-with-doom    shell integration
```

## Setup Process

### Prerequisites

- Nix with flakes enabled
- Home Manager configured
- macOS (Darwin) system

### Installation Steps

1. **Apply Configuration**

   ```bash
   # Build and switch to new configuration
   darwin-rebuild switch --flake .#J6G6Y9JK7L
   ```

2. **Verify Installation**

   ```bash
   # Check Doom Emacs availability
   which emacs
   emacs --version

   # Verify Doom modules
   emacs --batch --eval "(require 'doom-start)" 2>/dev/null && echo "Doom loaded successfully"
   ```

3. **Shell Integration**
   The configuration automatically sets up:
   - `EDITOR=emacs` environment variable
   - Emacs server daemon via launchd
   - File type associations for macOS

## Configuration Management

### Modifying Doom Modules

Edit [`home/dan/doom.d/init.el`](../home/dan/doom.d/init.el:1) to enable/disable modules:

```elisp
(doom! :input
       ;;chinese
       ;;kkc

       :completion
       company           ; the ultimate code completion backend
       ;;helm              ; the *other* search engine for love and life
       ;;ido               ; the other *other* search engine...
       (ivy +prescient)  ; a search engine for love and life)
```

**Important**: After modifying `init.el`, rebuild your system:

```bash
darwin-rebuild switch --flake .#J6G6Y9JK7L
```

### Adding Packages

Add packages to [`home/dan/doom.d/packages.el`](../home/dan/doom.d/packages.el:1):

```elisp
;; Nix-specific packages
(package! nixos-options)
(package! company-nixos-options)

;; Additional packages
(package! restclient)
(package! org-super-agenda)
```

### Personal Configuration

Customize behavior in [`home/dan/doom.d/config.el`](../home/dan/doom.d/config.el:1):

```elisp
;; Font configuration
(setq doom-font (font-spec :family "SF Mono" :size 13)
      doom-variable-pitch-font (font-spec :family "SF Pro Text" :size 14))

;; macOS specific settings
(when IS-MAC
  (setq mac-option-modifier 'meta
        mac-command-modifier 'super))
```

## Maintenance Procedures

### Regular Updates

1. **Update Flake Inputs**

   ```bash
   # Update all inputs
   nix flake update

   # Update specific input
   nix flake lock --update-input nix-doom-emacs-unstraightened
   ```

2. **Apply Updates**

   ```bash
   darwin-rebuild switch --flake .#J6G6Y9JK7L
   ```

3. **Verify Updates**
   ```bash
   # Check for any build issues
   nix build '.#darwinConfigurations.J6G6Y9JK7L.system' --dry-run
   ```

### Configuration Validation

Before applying changes, always validate:

```bash
# Dry run to check for issues
nix build '.#darwinConfigurations.J6G6Y9JK7L.system' --dry-run

# Check for syntax errors in Doom config
emacs --batch --load ~/.config/doom/init.el --eval "(message \"Config validated\")"
```

### Rollback Procedures

If issues occur:

1. **System Rollback**

   ```bash
   # List available generations
   darwin-rebuild --list-generations

   # Rollback to previous generation
   darwin-rebuild rollback
   ```

2. **Flake Rollback**
   ```bash
   # Restore previous flake.lock
   git checkout HEAD~1 -- flake.lock
   darwin-rebuild switch --flake .#J6G6Y9JK7L
   ```

## Troubleshooting

### Common Issues

#### Build Failures

**Symptom**: Nix build fails with package conflicts

```
error: collision between `/nix/store/...-package-a` and `/nix/store/...-package-b`
```

**Solution**: Check for duplicate package declarations in `packages.el` and ensure Doom modules don't conflict.

#### Missing Packages

**Symptom**: Doom complains about missing packages

```
Error: Package 'some-package' is not available
```

**Solution**:

1. Add package to [`packages.el`](../home/dan/doom.d/packages.el:1)
2. Rebuild system configuration
3. Restart Emacs

#### Performance Issues

**Symptom**: Slow Emacs startup or operation

**Solutions**:

1. Check for unnecessary modules in [`init.el`](../home/dan/doom.d/init.el:1)
2. Verify native compilation is working:
   ```elisp
   (native-comp-available-p)  ; Should return t
   ```
3. Clear Emacs cache:
   ```bash
   rm -rf ~/.config/emacs/.local/
   ```

#### macOS Integration Issues

**Symptom**: File associations or key bindings not working

**Solutions**:

1. Verify launchd agent is running:
   ```bash
   launchctl list | grep emacs
   ```
2. Check file associations:
   ```bash
   duti -l | grep emacs
   ```
3. Restart the Home Manager activation:
   ```bash
   /nix/store/*-activation-script/activate
   ```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Verbose Nix build
nix build '.#darwinConfigurations.J6G6Y9JK7L.system' --verbose

# Doom debug mode
emacs --debug-init

# Home Manager debug
home-manager switch --show-trace
```

## Best Practices

### Development Workflow

1. **Make Small Changes**: Test individual module changes before large modifications
2. **Use Version Control**: Commit working configurations before experimenting
3. **Test Builds**: Always run dry-run builds before applying changes
4. **Document Changes**: Keep notes on customizations for future reference

### Performance Optimization

1. **Selective Modules**: Only enable Doom modules you actually use
2. **Lazy Loading**: Prefer `after!` and `use-package!` with `:defer` for heavy packages
3. **Native Compilation**: Ensure all packages benefit from native compilation
4. **Regular Cleanup**: Periodically clean Nix store with `nix-collect-garbage`

### Security Considerations

1. **GPG Integration**: The configuration includes proper GPG agent setup for commit signing
2. **Package Sources**: All packages come from trusted nixpkgs or vetted Doom modules
3. **No External Downloads**: Avoid packages that download code at runtime
4. **Regular Updates**: Keep flake inputs updated for security patches

## Advanced Configuration

### Custom Doom Modules

Create local Doom modules in `~/.config/doom/modules/`:

```elisp
;; In config.el
(add-to-list 'doom-module-load-path "~/.config/doom/modules")
```

### Integration with Other Tools

The configuration integrates well with:

- **LSP Servers**: Automatically configured for Nix, Python, Rust, JavaScript
- **Git**: Full Magit integration with GPG signing
- **Terminal**: Multi-vterm support with proper shell integration
- **PDF Tools**: Complete PDF viewing and annotation support

### Customization Examples

```elisp
;; Custom keybindings
(map! :leader
      :prefix "o"
      :desc "Open terminal" "t" #'multi-vterm)

;; Project-specific settings
(dir-locals-set-class-variables 'nix-project
  '((nix-mode . ((tab-width . 2)
                 (nix-indent-function . 'nix-indent-line)))))

;; Custom snippets
(add-hook 'nix-mode-hook
          (lambda () (yas-activate-extra-mode 'nix-mode)))
```

## Support and Resources

- **Doom Emacs Documentation**: https://github.com/doomemacs/doomemacs
- **nix-doom-emacs-unstraightened**: https://github.com/marienz/nix-doom-emacs-unstraightened
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **Nixpkgs Manual**: https://nixos.org/manual/nixpkgs/stable/

## Appendix

### Configuration Files Summary

| File                                                                   | Purpose               | Frequency of Changes |
| ---------------------------------------------------------------------- | --------------------- | -------------------- |
| [`init.el`](../home/dan/doom.d/init.el:1)                              | Module selection      | Occasional           |
| [`config.el`](../home/dan/doom.d/config.el:1)                          | Personal settings     | Frequent             |
| [`packages.el`](../home/dan/doom.d/packages.el:1)                      | Package additions     | Occasional           |
| [`emacs-doom.nix`](../home/dan/features/productivity/emacs-doom.nix:1) | System integration    | Rare                 |
| [`flake.nix`](../flake.nix:1)                                          | Dependency management | Updates only         |

### Version Information

- **Emacs**: 30.1 with native compilation
- **Doom Emacs**: Latest from nix-doom-emacs-unstraightened
- **nix-doom-emacs-unstraightened**: Pinned via flake.lock
- **Home Manager**: Configured for macOS Darwin
- **Nix**: Flakes enabled configuration

This setup provides a robust, maintainable, and fully declarative Doom Emacs environment that integrates seamlessly with your Nix-based system configuration.
