= Emacs Setup Guide for macOS with Nix Darwin
:toc:
:toclevels: 3

== Overview

This guide covers the complete setup of Emacs on macOS using Nix Darwin and Home Manager, including troubleshooting common issues.

== Installation Steps

=== 1. Apply the Configuration

After adding the emacs.nix module to your configuration, rebuild your system:

[source,bash]
----
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
----

=== 2. First-Time Setup

After the initial installation, perform these one-time setup steps:

==== Install Icon Fonts

Launch Emacs and run the following command to install icon fonts:

[source,elisp]
----
M-x all-the-icons-install-fonts
----

This ensures proper icon display in the modeline and file browser.

==== Verify Daemon Setup

Check if the Emacs daemon is running:

[source,bash]
----
# Check if daemon is running
ps aux | grep emacs

# Test emacsclient
emacsclient -c
----

== Configuration Features

=== Core Features Included

* **Latest Emacs 30** from nixpkgs-unstable
* **Comprehensive package set** for productivity and development
* **Nix ecosystem integration** with nix-mode, nixos-options, and LSP support
* **macOS optimization** with proper PATH inheritance and keybindings
* **Daemon service** for instant startup
* **Modern UI** with Doom themes and modeline

=== Key Packages

[cols="2,3"]
|===
| Category | Packages

| **Core Framework**
| use-package, company, ivy/counsel/swiper

| **Nix Support**
| nix-mode, nixos-options, company-nixos-options, nixd

| **Development**
| lsp-mode, lsp-ui, flycheck, yasnippet, magit

| **UI/Themes**
| doom-themes, doom-modeline, all-the-icons

| **File Management**
| projectile, treemacs, dired-sidebar

| **macOS Integration**
| exec-path-from-shell
|===

=== Shell Integration

The configuration provides these convenient aliases:

[source,bash]
----
e filename      # Edit file (non-blocking)
ec              # New Emacs frame
et              # Terminal mode
emacs-restart   # Restart daemon
----

== Troubleshooting Guide

=== Common Issues and Solutions

==== 1. Font Rendering Issues

**Problem:** Fonts look incorrect or inconsistent.

**Solutions:**

[source,bash]
----
# The configuration already includes NerdFonts
# If you need additional fonts, rebuild after adding them
----

**Emacs font configuration:**
[source,elisp]
----
;; Add to your init file for custom fonts
(set-face-attribute 'default nil
                    :family "JetBrains Mono"
                    :height 140
                    :weight 'medium)
----

==== 2. PATH Integration Issues

**Problem:** Emacs can't find system tools or has incorrect PATH.

**Solutions:**

[source,elisp]
----
;; Already included in configuration - exec-path-from-shell
;; If issues persist, manually check:
M-x getenv RET PATH

;; To debug PATH issues:
M-x shell-command RET echo $PATH
----

**Alternative solution:**
[source,bash]
----
# Add to your shell profile
export PATH="/run/current-system/sw/bin:$PATH"
----

==== 3. GUI Application Launch Issues

**Problem:** Emacs doesn't appear in Spotlight or Application folder.

**Solutions:**

[source,bash]
----
# Rebuild and reset Launch Services
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
----

**Manual app creation:**
[source,bash]
----
# Create app alias (if needed)
ln -s /run/current-system/sw/Applications/Emacs.app ~/Applications/
----

==== 4. Daemon Service Issues

**Problem:** Emacs daemon not starting automatically.

**Solutions:**

[source,bash]
----
# Check service status
launchctl list | grep emacs

# Manually start daemon
emacs --daemon

# Restart daemon
pkill -f emacs
emacs --daemon
----

**Force daemon restart:**
[source,bash]
----
# Use the provided alias
emacs-restart
----

==== 5. Package Loading Errors

**Problem:** Emacs packages fail to load or compile.

**Solutions:**

[source,elisp]
----
;; Clear package compilation cache
M-x byte-recompile-directory RET ~/.emacs.d RET

;; Or start with clean config
emacs -Q
----

**Nix-specific solution:**
[source,bash]
----
# Rebuild with clean package cache
nix-collect-garbage -d
sudo darwin-rebuild switch --flake ~/dev/PRIVATE/nix-config
----

==== 6. LSP Server Issues

**Problem:** Language servers not working correctly.

**Solutions:**

[source,elisp]
----
;; Check LSP server status
M-x lsp-doctor

;; Restart LSP server
M-x lsp-restart-workspace
----

**For Nix files specifically:**
[source,bash]
----
# Ensure nixd is available
which nixd

# Check nixd configuration
nixd --help
----

=== macOS-Specific Issues

==== Window Management

**Problem:** Emacs windows behave differently than other macOS apps.

**Solution:**
[source,elisp]
----
;; Add to configuration for better macOS integration
(setq ns-use-native-fullscreen t
      ns-use-fullscreen-animation t
      mac-allow-anti-aliasing t)
----

==== Keyboard Shortcuts

**Problem:** Keyboard shortcuts conflict with system shortcuts.

**Solution:**
The configuration sets up proper macOS key bindings:
- `Option` → `Meta`
- `Command` → `Super`
- Right `Option` → `nil` (for international characters)

== Performance Optimization

=== Startup Performance

The daemon service provides instant startup, but you can optimize further:

[source,elisp]
----
;; Add to configuration for faster startup
(setq gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024))

;; Reset after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 800000)))
----

=== Memory Usage

[source,elisp]
----
;; Monitor memory usage
M-x memory-report

;; Clear unnecessary buffers
M-x clean-buffer-list
----

== Usage Tips

=== Essential Keybindings

[cols="2,3"]
|===
| Binding | Function

| `C-x g`
| Open Magit (Git interface)

| `C-c p`
| Projectile commands

| `C-s`
| Swiper search

| `M-x counsel-`
| Various Counsel commands

| `C-c l`
| LSP commands

| `s-=`, `s--`, `s-0`
| Text scaling (macOS)
|===

=== Nix-Specific Commands

[source,elisp]
----
;; Browse NixOS options
M-x nixos-options

;; Format Nix code
M-x nix-format-buffer

;; LSP actions in Nix files
M-x lsp-execute-code-action
----

== Advanced Configuration

=== Custom Package Management

If you need additional packages not in the base configuration:

[source,nix]
----
# Add to extraPackages in emacs.nix
extraPackages = epkgs: with epkgs; [
  # Your additional packages here
  pdf-tools
  org-noter
  helm  # Alternative to ivy
];
----

=== Custom Configuration

Add custom Elisp to the `extraConfig` section:

[source,nix]
----
extraConfig = ''
  ;; Your custom configuration
  (setq custom-variable value)
  
  ;; Custom keybindings
  (global-set-key (kbd "C-c C-c") 'custom-function)
'';
----

== Getting Help

=== Built-in Help

[source,elisp]
----
C-h ?           # Help menu
C-h k <key>     # Describe key
C-h f <func>    # Describe function
C-h v <var>     # Describe variable
C-h m           # Current mode help
----

=== Community Resources

* https://emacs.stackexchange.com/[Emacs Stack Exchange]
* https://www.reddit.com/r/emacs/[r/emacs subreddit]
* https://github.com/nix-community/home-manager[Home Manager documentation]
* https://nixos.org/manual/nixpkgs/stable/#sec-emacs[Nixpkgs Emacs documentation]

== Conclusion

This configuration provides a robust, modern Emacs setup optimized for macOS and Nix development. The declarative approach ensures reproducibility across different systems while maintaining the flexibility that makes Emacs powerful.

Remember to restart the daemon after making configuration changes and rebuild your system to apply Nix-level modifications.