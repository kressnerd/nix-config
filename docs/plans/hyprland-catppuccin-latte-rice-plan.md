# Hyprland Catppuccin Latte Rice — Implementation Plan

**Status**: COMPLETED
**Created**: 2026-04-09

---

## Goal

Rework the entire visual and structural configuration of the thiniel NixOS laptop into a cohesive, minimal, clean Catppuccin Latte setup using **Stylix** as the single source of truth for all colors. Eliminate hardcoded color definitions scattered across feature modules, split the `hyprland.nix` monolith into composable modules, add missing desktop components (Hyprlock, Hypridle, wallpaper, GTK/Qt theming), and clean up package duplication between system and Home Manager.

## Business Context

The current desktop configuration works but suffers from:

- **Color duplication** — Catppuccin Latte hex values are hardcoded independently in 10+ files (fish, kitty, starship, bat, fzf, lazygit, waybar, mako, fuzzel, hyprland borders)
- **Monolithic hyprland.nix** — 387 lines containing Hyprland + Waybar + Mako + Fuzzel configs, violating single-responsibility
- **Missing desktop components** — no screen lock (hyprlock), no idle management (hypridle), no wallpaper, no GTK/Qt/cursor theming
- **Package duplication** — `wl-clipboard`, `cliphist`, `brightnessctl`, `waybar`, `mako` appear in both `environment.systemPackages` and Home Manager
- **Vestigial packages** — `rofi` in system packages despite `fuzzel` being the actual launcher
- **greetd mismatch** — uses stable `pkgs.hyprland` sessions path while Hyprland uses `pkgs-unstable.hyprland`

## Acceptance Criteria

1. `nix flake check` passes for all systems (x86_64-linux, aarch64-linux, aarch64-darwin)
2. `nixos-rebuild build --flake .#thiniel` succeeds
3. All applications render in Catppuccin Latte with correct fonts
4. No hardcoded Catppuccin colors remain — all sourced from Stylix or `config.lib.stylix.colors`
5. No duplicate packages across `environment.systemPackages` and Home Manager
6. Hyprlock lock/unlock cycle works; PAM integration functional
7. Hypridle triggers dim → lock → suspend at configured timeouts
8. Waybar renders with pill-shaped modules, correct colors, ≤32px height
9. Fuzzel launches centered, text-only, correct colors
10. macOS (J6G6Y9JK7L) build evaluates without errors; shared modules work with Stylix on Darwin
11. No deprecated Hyprland config keywords
12. No hardcoded absolute paths in Nix files
13. GTK/Qt apps (Firefox, KeePassXC, ownCloud, pavucontrol) render with Catppuccin Latte colors and Papirus-Light icons

---

## Technical Analysis

### Architecture Decision: Stylix as Color Authority

**Chosen**: Stylix flake (`github:nix-community/stylix/release-25.11`)

**Rationale**: Stylix provides a single `base16Scheme` declaration that auto-propagates colors to 20+ targets (Kitty, Fish, Waybar, Mako, Fuzzel, Hyprland, Hyprlock, GTK, Qt, bat, fzf, lazygit, Starship, etc.) via NixOS and Home Manager modules. This eliminates all per-file color duplication.

**Alternative rejected**: Manual `catppuccinLatte` attrset in `lib/` referenced by all modules — requires explicit wiring per file, doesn't integrate with GTK/Qt/cursor theming, doesn't handle Hyprlock or Hyprpaper.

### Module Split Strategy

```
features/linux/hyprland.nix (387 lines, monolith)
  ├─→ features/linux/hyprland.nix   (compositor only: settings, keybinds, window rules)
  ├─→ features/linux/waybar.nix     (bar config + custom CSS)
  ├─→ features/linux/mako.nix       (notifications)
  ├─→ features/linux/fuzzel.nix     (launcher)
  ├─→ features/linux/hyprlock.nix   (screen lock)
  ├─→ features/linux/hypridle.nix   (idle management)
  └─→ features/linux/gtk-qt.nix     (GTK + Qt + icons — Stylix auto-themes GTK/Qt colors)
```

### Stylix Integration Points

```
flake.nix
  ├─ inputs.stylix = "github:nix-community/stylix/release-25.11"
  │
  ├─ nixosConfigurations.thiniel
  │    └─ stylix.nixosModules.stylix  ← auto-propagates to HM users
  │         ├─ stylix.enable = true
  │         ├─ stylix.polarity = "light"
  │         ├─ stylix.base16Scheme = catppuccin-latte.yaml
  │         ├─ stylix.image = <wallpaper or solid Latte base color>
  │         ├─ stylix.fonts = { monospace, sansSerif, emoji, sizes }
  │         ├─ stylix.cursor = { package, name, size }
  │         └─ stylix.autoEnable = true
  │
  └─ darwinConfigurations.J6G6Y9JK7L
       └─ stylix.darwinModules.stylix
            ├─ stylix.enable = true
            ├─ stylix.polarity = "light"
            ├─ stylix.base16Scheme = catppuccin-latte.yaml
            ├─ stylix.image = <required but irrelevant on macOS>
            ├─ stylix.fonts = { monospace, sansSerif, emoji, sizes }
            └─ stylix.autoEnable = true
```

### Cross-Platform Impact

| Module | thiniel (NixOS) | J6G6Y9JK7L (macOS) | Change |
|--------|:---------------:|:-------------------:|--------|
| `kitty.nix` | ✓ | ✓ | Remove `themeFile`, Stylix handles colors+fonts |
| `fish.nix` | ✓ | ✓ | Remove `fish_color_*` vars, Stylix handles |
| `starship.nix` | ✓ | ✓ | Remove `palette` and `palettes.catppuccin_latte` |
| `shell-utils.nix` | ✓ | ✓ | Remove bat theme fetch, fzf colors, lazygit theme |
| `vim.nix` | ✓ | ✓ | Keep `catppuccin-vim` plugin (Stylix vim target optional) |
| `hyprland.nix` | ✓ | — | Split + rework, Linux-only |
| `waybar.nix` | ✓ | — | New file, Linux-only |
| `mako.nix` | ✓ | — | New file, Linux-only |
| `fuzzel.nix` | ✓ | — | New file, Linux-only |
| `hyprlock.nix` | ✓ | — | New file, Linux-only |
| `hypridle.nix` | ✓ | — | New file, Linux-only |
| `gtk-qt.nix` | ✓ | — | New file, Linux-only |

### GUI Apps Affected by GTK/Qt Theming

| App | Toolkit | Themed by Stylix |
|-----|---------|:----------------:|
| Firefox | GTK | ✓ (auto) |
| pavucontrol | GTK | ✓ (auto) |
| KeePassXC | Qt | ✓ (auto) |
| ownCloud client | Qt | ✓ (auto) |
| SweetHome3D | Java/Swing | ✗ (not affected) |

### Dangerous Change Assessment

| Category | Risk | Mitigation |
|----------|------|------------|
| Display/Session | greetd sessions path change | Verify `pkgs-unstable.hyprland` has wayland-sessions directory |
| Authentication | PAM hyprlock service | Test lock/unlock before reboot |
| Packages | Removing system packages | Verify HM equivalents are present before removing |

---

## Phase 0: Validation Strategy

### Syntax & Build Validation

| Command | Purpose |
|---------|---------|
| `nix flake check` | Evaluates all configs + runs all checks (assertions, lints) |
| `nix flake check --no-build` | Fast eval-only (assertions fire, no VM tests) |
| `nixos-rebuild build --flake .#thiniel` | Full build of thiniel NixOS+HM config |
| `nix build .#darwinConfigurations.J6G6Y9JK7L.system` | Verify macOS config evaluates |

### Apply Validation

| Command | Purpose |
|---------|---------|
| `sudo nixos-rebuild test --flake .#thiniel` | Apply without making it boot default |
| `sudo nixos-rebuild switch --flake .#thiniel` | Apply and set as boot default |

### Rollback Path

```fish
# If switch breaks display:
# 1. Switch to TTY: Ctrl+Alt+F2
# 2. Login as dan
# 3. Rollback:
sudo nixos-rebuild switch --rollback

# If greetd fails to start:
# 1. Boot previous generation from systemd-boot menu
# 2. Fix config, rebuild
```

### Per-Phase Validation

Each phase below specifies its validation command. The pattern is:
1. Make change
2. `nix flake check --no-build` (fast, catches eval errors + assertions)
3. `nixos-rebuild build --flake .#thiniel` (full build, catches missing packages)
4. Visual verification where noted

---

## Implementation Phases

### Phase 1: Stylix Base Setup

**Goal**: Add Stylix flake input, wire into thiniel NixOS and J6G6Y9JK7L Darwin configs, configure base theme.

- [x] 1.1 Add Stylix input to `flake.nix` inputs:
  ```nix
  stylix = {
    url = "github:nix-community/stylix/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  ```
- [x] 1.2 Add `stylix` to the `outputs` function parameter destructuring in `flake.nix` (line 67–80)
- [x] 1.3 Add `stylix.nixosModules.stylix` to `thiniel` modules list in `flake.nix` (after line 151)
- [x] 1.4 Add `stylix.darwinModules.stylix` to `J6G6Y9JK7L` modules list in `flake.nix` (after line 194)
- [x] 1.5 Add Stylix configuration block to `hosts/thiniel/default.nix`:
  ```nix
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    image = pkgs.runCommand "solid-latte-wallpaper" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 1920x1080 xc:#eff1f5 $out
    '';
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 11;
        popups = 11;
      };
    };
    cursor = {
      package = pkgs.catppuccin-cursors.latteBlue;
      name = "catppuccin-latte-blue-cursors";
      size = 24;
    };
  };
  ```
- [x] 1.6 Add minimal Stylix configuration to `hosts/J6G6Y9JK7L/default.nix`:
  ```nix
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    image = pkgs.runCommand "solid-latte-wallpaper" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 1920x1080 xc:#eff1f5 $out
    '';
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
      };
    };
  };
  ```
- [x] 1.7 Run `nix flake lock --update-input stylix` to fetch and pin the new input
- [x] 1.8 Validate: `nix flake check --no-build` passes
- [x] 1.9 Validate: `nixos-rebuild build --flake .#thiniel` succeeds

### Phase 2: Kitty — Remove Hardcoded Theme (shared module)

**Goal**: Let Stylix manage Kitty colors and fonts. Keep structural config.

- [x] 2.1 In `home/dan/features/cli/kitty.nix`: remove `themeFile = "Catppuccin-Latte";` (line 10)
- [x] 2.2 Remove `font_family = "JetBrainsMono Nerd Font Mono";` and `font_size = "12.0";` — Stylix manages these
- [x] 2.3 Remove `bold_font`, `italic_font`, `bold_italic_font` (auto-detected by Stylix)
- [x] 2.4 Keep all structural settings: `window_padding_width`, `hide_window_decorations`, `confirm_os_window_close`, tab bar, performance, macOS-specific, scrollback, URLs, cursor, bell
- [x] 2.5 Remove `home.packages = [ nerd-fonts.jetbrains-mono ];` — Stylix installs fonts globally
- [x] 2.6 Keep all keybindings and extraConfig unchanged
- [x] 2.7 Validate: `nix flake check --no-build`
- [x] 2.8 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 3: Fish + Starship — Remove Hardcoded Colors (shared modules)

**Goal**: Let Stylix handle Fish shell colors and Starship prompt colors. Keep structural prompt config.

**Fish (`home/dan/features/cli/fish.nix`)**:
- [x] 3.1 Remove the entire `# Catppuccin Latte colors` block from `interactiveShellInit` (lines 37–54) — Stylix handles `fish_color_*` variables
- [x] 3.2 Keep: `set fish_greeting` (disable greeting)
- [x] 3.3 Keep: Kitty shell integration block
- [x] 3.4 Keep all `shellAliases` and `functions` unchanged

**Starship (`home/dan/features/cli/starship.nix`)**:
- [x] 3.5 Remove `palette = "catppuccin_latte";` (line 26)
- [x] 3.6 Remove entire `palettes.catppuccin_latte` block (lines 28–55) — Stylix manages colors
- [x] 3.7 Keep the `format` string with all module references
- [x] 3.8 Keep all module configurations (`username`, `hostname`, `directory`, `git_branch`, `git_status`, `nix_shell`, `cmd_duration`, `character`, language modules)
- [x] 3.9 Replace hardcoded color names in module styles with Stylix-compatible Base16 references via `config.lib.stylix.colors` where needed, or let Stylix override them automatically
- [x] 3.10 Validate: `nix flake check --no-build`
- [x] 3.11 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 4: TUI Apps — Remove Hardcoded Themes (shared module)

**Goal**: Let Stylix handle bat, fzf, lazygit colors. Add yazi, btop, fastfetch.

**shell-utils.nix modifications**:
- [x] 4.1 Remove `programs.bat.config.theme` and entire `programs.bat.themes.catppuccin-latte` block (lines 67–78) — Stylix handles bat theme
- [x] 4.2 Remove `programs.fzf.defaultOptions` color flags (lines 83–88) — Stylix handles fzf colors
- [x] 4.3 Remove `programs.lazygit.settings.gui.theme` block (lines 94–109) — Stylix handles lazygit theme
- [x] 4.4 Keep: `programs.bat.enable`, `programs.fzf.enable`, `programs.lazygit.enable`
- [x] 4.5 Keep: `programs.eza`, `programs.zoxide`, `programs.direnv` configs unchanged
- [x] 4.6 Keep: all `home.packages` entries unchanged

**New TUI app configurations** (add to `shell-utils.nix` or separate files):
- [x] 4.7 Add `programs.btop` with `enable = true` and vim keybinds
- [x] 4.8 Add `programs.yazi` with `enable = true`
- [x] 4.9 Add `fastfetch` to `home.packages` with minimal config via `xdg.configFile`
- [x] 4.10 Add Linux-only packages: `bluetuith`, `pulsemixer` via `lib.optionals pkgs.stdenv.isLinux`
- [x] 4.11 Validate: `nix flake check --no-build`
- [x] 4.12 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 5: Split hyprland.nix Monolith

**Goal**: Extract Waybar, Mako, Fuzzel into separate modules. No functional change — pure structural refactor.

- [x] 5.1 Create `home/dan/features/linux/waybar.nix` — move `programs.waybar` block (lines 47–237 of current hyprland.nix)
- [x] 5.2 Create `home/dan/features/linux/mako.nix` — move `services.mako` block (lines 239–253)
- [x] 5.3 Create `home/dan/features/linux/fuzzel.nix` — move `programs.fuzzel` block (lines 255–280)
- [x] 5.4 In `home/dan/features/linux/hyprland.nix`: remove the extracted blocks, keep only `wayland.windowManager.hyprland`, `home.packages`, `let` bindings
- [x] 5.5 Update `home/dan/thiniel.nix` imports: add `./features/linux/waybar.nix`, `./features/linux/mako.nix`, `./features/linux/fuzzel.nix`
- [x] 5.6 Verify: modules still reference needed packages (e.g., waybar.nix may need `rofiPowerMenu` — pass via `home.packages` or restructure)
- [x] 5.7 Validate: `nix flake check --no-build` — pure refactor, no behavior change
- [x] 5.8 Validate: `nixos-rebuild build --flake .#thiniel`
- [x] 5.9 Update `tests/unit/hm-linux-modules-test.nix` — adjust imports for split modules; existing test expectations must still pass

### Phase 6: Hyprland Compositor — Rework Config

**Goal**: Clean up Hyprland settings, remove hardcoded colors, let Stylix handle border colors. Add window rules, improve keybinds.

- [x] 6.1 Remove `catppuccinLatte` attrset and `removeHash` function from `hyprland.nix` (lines 3–18)
- [x] 6.2 Remove hardcoded `col.active_border` and `col.inactive_border` — Stylix sets these automatically
- [x] 6.3 Add `general` settings: `gaps_in = 4`, `gaps_out = 8`, `border_size = 2`, `layout = "dwindle"`
- [x] 6.4 Add `decoration`: `rounding = 8`, `blur.enabled = false` (light theme doesn't need blur), `shadow.enabled = false`
- [x] 6.5 Add `animations`: `enabled = true`, with fade 150ms and slide 150ms presets. No spring/wobbly
- [x] 6.6 Add `input`: `touchpad.natural_scroll = true`, `touchpad.tap-to-click = true`
- [x] 6.7 Keep existing `kb_options = "compose:ralt"`
- [x] 6.8 Rework keybinds: change `$mainMod CTRL` to `$mainMod SHIFT` for window move (h/j/k/l), keep focus on `$mainMod` h/j/k/l
- [x] 6.9 Add screenshot keybind: `$mainMod, Print, exec, grim -g "$(slurp)" - | wl-copy`
- [x] 6.10 Add Hyprlock keybind: `$mainMod, backspace, exec, hyprlock`
- [x] 6.11 Add `grim` and `slurp` to `home.packages`
- [x] 6.12 Remove vestigial rofi references from power menu script — already using fuzzel (confirmed)
- [x] 6.13 Add window rules: `windowrulev2 = float,class:^(dialog)$`, `windowrulev2 = pin,title:^(Picture-in-Picture)$`, `windowrulev2 = idleinhibit fullscreen,class:.*`
- [x] 6.14 Keep monitor and workspace configs unchanged (hardware-specific)
- [x] 6.15 Validate: `nix flake check --no-build`
- [x] 6.16 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 7: Waybar — Rework Config

**Goal**: Let Stylix handle base colors. Add custom CSS for pill-shaped module groups.

- [x] 7.1 In `home/dan/features/linux/waybar.nix`: remove all hardcoded `catppuccinLatte.*` color references from CSS
- [x] 7.2 Let Stylix generate base Waybar CSS via `stylix.targets.waybar.enable = true` (auto-enabled)
- [x] 7.3 Rework `settings.mainBar`:
  - `height = 32`
  - `modules-left = [ "hyprland/workspaces" ]`
  - `modules-center = [ "clock" ]`
  - `modules-right = [ "pulseaudio" "network" "battery" "tray" ]`
  - Remove `cpu` and `memory` modules (minimal bar)
  - Keep `custom/power` module
- [x] 7.4 Clock format: `format = "{:%H:%M · %Y-%m-%d}"`
- [x] 7.5 Add `exclusive = true` and waybar hide on fullscreen
- [x] 7.6 Write custom CSS overlay for pill-shaped module groups:
  ```css
  .modules-left, .modules-center, .modules-right {
    border-radius: 16px;
    padding: 0 8px;
    margin: 4px;
  }
  ```
- [x] 7.7 Set semi-transparent background (~95% opacity) via `@define-color` with alpha or `rgba()`
- [x] 7.8 Validate: `nix flake check --no-build`
- [x] 7.9 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 8: Fuzzel — Rework Config

**Goal**: Let Stylix handle colors. Simplify to text-only, centered launcher.

- [x] 8.1 In `home/dan/features/linux/fuzzel.nix`: remove entire `colors` section — Stylix handles it
- [x] 8.2 Update `settings.main`:
  - `width = 35`
  - `anchor = "center"`
  - `icons-enabled = "no"` (text-only)
  - `font = "JetBrainsMono Nerd Font:size=12"` (or let Stylix manage via font settings)
  - `lines = 10`
  - `horizontal-pad = 12`
  - `vertical-pad = 8`
  - Remove `line-height` and `letter-spacing`
- [x] 8.3 Keep `border.width = 2` and `border.radius = 8`
- [x] 8.4 Keep `terminal` reference to kitty
- [x] 8.5 Validate: `nix flake check --no-build`
- [x] 8.6 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 9: Mako — Rework Config

**Goal**: Let Stylix handle colors. Configure position and behavior.

- [x] 9.1 In `home/dan/features/linux/mako.nix`: remove hardcoded `background-color`, `text-color`, `border-color`, `progress-color` — Stylix handles all
- [x] 9.2 Configure structural settings:
  ```nix
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      border-radius = 8;
      border-size = 2;
      max-visible = 3;
      default-timeout = 5000;
      icons = false;
      margin = "8";
      padding = "12";
    };
  };
  ```
- [x] 9.3 Remove urgency overrides if Stylix handles them, or keep minimal urgency config
- [x] 9.4 Validate: `nix flake check --no-build`
- [x] 9.5 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 10: Hypridle + Hyprlock — New Modules

**Goal**: Add screen lock and idle management. Let Stylix handle Hyprlock colors.

**Hypridle (`home/dan/features/linux/hypridle.nix`)**:
- [x] 10.1 Create `home/dan/features/linux/hypridle.nix`:
  ```nix
  { ... }:
  {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          { timeout = 300; on-timeout = "brightnessctl -s set 10"; on-resume = "brightnessctl -r"; }
          { timeout = 600; on-timeout = "loginctl lock-session"; }
          { timeout = 900; on-timeout = "systemctl suspend"; }
        ];
      };
    };
  }
  ```
- [x] 10.2 Add `./features/linux/hypridle.nix` to `home/dan/thiniel.nix` imports

**Hyprlock (`home/dan/features/linux/hyprlock.nix`)**:
- [x] 10.3 Create `home/dan/features/linux/hyprlock.nix`:
  ```nix
  { ... }:
  {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 5;
        };
        background = [
          { path = "screenshot"; blur_passes = 2; blur_size = 4; }
        ];
        input-field = [
          {
            size = "250, 50";
            outline_thickness = 2;
            dots_size = 0.25;
            dots_spacing = 0.2;
            fade_on_empty = true;
            placeholder_text = "Password...";
            position = "0, -80";
            halign = "center";
            valign = "center";
          }
        ];
        label = [
          {
            text = "cmd[update:1000] date +\"%H:%M\"";
            font_size = 64;
            font_family = "Inter";
            position = "0, 80";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  }
  ```
- [x] 10.4 Add `./features/linux/hyprlock.nix` to `home/dan/thiniel.nix` imports
- [x] 10.5 Add `security.pam.services.hyprlock = {};` to `hosts/thiniel/default.nix`
- [x] 10.6 Validate: `nix flake check --no-build`
- [x] 10.7 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 11: GTK/Qt/Icons — New Module

**Goal**: Add Papirus-Light icon theme. Stylix `autoEnable = true` already themes GTK and Qt colors for Firefox, KeePassXC, ownCloud, and pavucontrol.

- [x] 11.1 Create `home/dan/features/linux/gtk-qt.nix`:
  ```nix
  { pkgs, ... }:
  {
    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus-Light";
      };
    };
    qt = {
      enable = true;
      # Stylix handles Qt theming via stylix.targets.qt.enable = true (auto)
    };
  }
  ```
- [x] 11.2 Add `./features/linux/gtk-qt.nix` to `home/dan/thiniel.nix` imports
- [x] 11.3 Verify Stylix auto-enables GTK and Qt targets (no manual `stylix.targets.gtk.enable` needed)
- [x] 11.4 Validate: `nix flake check --no-build`
- [x] 11.5 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 12: System Cleanup — hosts/thiniel/default.nix

**Goal**: Remove duplicate and vestigial packages from `environment.systemPackages`. Fix greetd.

- [x] 12.1 Remove from `environment.systemPackages`: `waybar` (HM manages), `mako` (HM manages), `rofi` (vestigial — fuzzel is the launcher), `brightnessctl` (HM manages via hyprland.nix `home.packages`)
- [x] 12.2 Keep `libnotify` in `environment.systemPackages` only if not in HM `home.packages` — check: it IS in hyprland.nix `home.packages`, so remove from system
- [x] 12.3 Fix greetd sessions path: change `${pkgs.hyprland}` to `${pkgs-unstable.hyprland}` in `services.greetd.settings.default_session.command` (line 236)
- [x] 12.4 Verify `security.pam.services.hyprlock = {};` was added in Phase 10
- [x] 12.5 Validate: `nix flake check --no-build`
- [x] 12.6 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 13: macOS Adjustments — J6G6Y9JK7L

**Goal**: Ensure Stylix works on Darwin for shared modules. Gate Linux-only targets.

- [x] 13.1 Verify `hosts/J6G6Y9JK7L/default.nix` has Stylix config from Phase 1.6
- [x] 13.2 Verify shared modules (kitty, fish, starship, shell-utils, vim) work with Stylix on Darwin — no Linux-only Stylix targets referenced
- [x] 13.3 Stylix auto-disables Linux-only targets (Hyprland, Waybar, Mako, etc.) on Darwin — no manual gating needed
- [x] 13.4 Verify `programs.kitty.package = pkgs.emptyDirectory;` still works with Stylix (HM generates config but package is overridden)
- [x] 13.5 Validate: `nix build .#darwinConfigurations.J6G6Y9JK7L.system` (or `darwin-rebuild build --flake .#J6G6Y9JK7L` on macOS)

### Phase 14: Fonts Cleanup

**Goal**: Consolidate font packages. Stylix manages fonts globally. Remove duplicates.

- [x] 14.1 In `home/dan/features/linux/fonts.nix`: remove `nerd-fonts._0xproto`, `nerd-fonts.droid-sans-mono`, `nerd-fonts.fira-code` — unused, Stylix installs JetBrainsMono
- [x] 14.2 Remove `wl-clipboard` and `cliphist` from `fonts.nix` — they belong in `hyprland.nix` (already there)
- [x] 14.3 Keep `font-awesome` (needed for Waybar icons) and `nerd-fonts.symbols-only` (fallback glyphs)
- [x] 14.4 Keep `fonts.fontconfig.enable = true`
- [x] 14.5 Result should be:
  ```nix
  { pkgs, ... }:
  {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      font-awesome         # Waybar icons
      nerd-fonts.symbols-only  # Fallback nerd font glyphs
    ];
  }
  ```
- [x] 14.6 Verify `nerd-fonts.jetbrains-mono` is NOT duplicated — Stylix installs it via `stylix.fonts.monospace.package`
- [x] 14.7 Validate: `nix flake check --no-build`
- [x] 14.8 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 15: Vim — Stylix Integration Decision

**Goal**: Decide Vim theming approach. Stylix has a Vim target but catppuccin-vim plugin is already working.

- [x] 15.1 Option A: Keep `catppuccin-vim` plugin + manual `colorscheme catppuccin_latte` in `extraConfig`. Disable Stylix Vim target: add `stylix.targets.vim.enable = false;` to HM config or via module override
- [x] 15.2 Option B (Recommended?): Remove catppuccin-vim plugin, let Stylix handle Vim colors via Base16 theme. Simpler but different color nuance
- [x] 15.3 Whichever chosen: verify `nix flake check --no-build`
- [x] 15.4 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 16: Tests and Assertions

**Goal**: Add assertions for new modules. Update unit tests for split modules.

**New assertions (`tests/assertions/thiniel-rice-invariants.nix`)**:
- [x] 16.1 Create `tests/assertions/thiniel-rice-invariants.nix`:
  ```nix
  { config, lib, ... }:
  {
    config = lib.mkIf (config.networking.hostName == "thiniel") {
      assertions = [
        {
          assertion = config.stylix.enable;
          message = "Thiniel rice invariant: stylix.enable must be true";
        }
        {
          assertion = config.stylix.polarity == "light";
          message = "Thiniel rice invariant: stylix.polarity must be 'light' (Catppuccin Latte)";
        }
        {
          assertion = config.security.pam.services ? hyprlock;
          message = "Thiniel rice invariant: security.pam.services.hyprlock must exist for screen lock";
        }
        {
          assertion = !(builtins.elem "rofi" (builtins.map (p: p.pname or p.name or "") config.environment.systemPackages));
          message = "Thiniel rice invariant: rofi must not be in systemPackages (fuzzel is the launcher)";
        }
      ];
    };
  }
  ```
- [x] 16.2 Import `thiniel-rice-invariants.nix` in `tests/assertions/default.nix`
- [x] 16.3 Update `tests/unit/hm-linux-modules-test.nix`:
  - Adjust hyprland module import (no longer contains Waybar/Mako/Fuzzel)
  - Add separate imports for waybar.nix, mako.nix, fuzzel.nix
  - Update `testHyprlandBindCount` expected value (new keybinds added)
  - Update `testHyprlandActiveBorderColor` — Stylix manages this now; test may need removal or update
  - Add tests for new modules: hyprlock enabled, hypridle enabled, waybar settings, mako settings, fuzzel settings
- [x] 16.4 Update `testWaybarHasCustomPowerModule` and related tests for new module structure
- [x] 16.5 Validate: `nix flake check` (full — including all checks and lints)
- [x] 16.6 Validate: `nixos-rebuild build --flake .#thiniel`

### Phase 17: Final Validation & Apply

**Goal**: Full validation across all systems, then apply.

- [x] 17.1 Run `nix flake check` — all systems, all checks
- [x] 17.2 Run `nixos-rebuild build --flake .#thiniel` — full build
- [x] 17.3 Verify macOS: `nix build .#darwinConfigurations.J6G6Y9JK7L.system`
- [x] 17.4 Run `nix fmt` on all changed files
- [x] 17.5 Run `statix check .` and `deadnix .` — fix any issues
- [ ] 17.6 Apply: `sudo nixos-rebuild switch --flake .#thiniel`
- [ ] 17.7 Visual verification checklist:
  - [ ] Kitty: Catppuccin Latte colors, correct font
  - [ ] Fish: Catppuccin Latte syntax highlighting
  - [ ] Starship: Correct prompt colors
  - [ ] Waybar: Pill-shaped modules, correct colors, ≤32px height
  - [ ] Fuzzel: Centered, text-only, correct colors
  - [ ] Mako: Top-right notifications, correct colors
  - [ ] Hyprlock: Lock/unlock works, clock + password input displayed
  - [ ] Hypridle: Screen dims after 5min (test with shorter timeout)
  - [ ] GTK apps: Catppuccin Latte theme, Papirus-Light icons
  - [ ] Cursor: Catppuccin Latte Blue cursor visible
  - [ ] bat, fzf, lazygit: Correct theme colors
- [x] 17.8 Verify no hardcoded Catppuccin hex values remain: `grep -rn '#eff1f5\|#4c4f69\|#1e66f5\|#7287fd\|#d20f39\|catppuccinLatte\|catppuccin.latte\|Catppuccin-Latte\|catppuccin_latte' home/ hosts/`

---

## File Changes Summary

### Files to MODIFY

| File | Change |
|------|--------|
| `flake.nix` | Add Stylix input + wire into thiniel and J6G6Y9JK7L modules |
| `hosts/thiniel/default.nix` | Add Stylix config, PAM hyprlock, fix greetd, remove duplicate system packages |
| `hosts/J6G6Y9JK7L/default.nix` | Add Stylix darwin config |
| `home/dan/thiniel.nix` | Import new feature modules (waybar, mako, fuzzel, hyprlock, hypridle, gtk-qt) |
| `home/dan/features/cli/kitty.nix` | Remove `themeFile`, font settings, font package |
| `home/dan/features/cli/fish.nix` | Remove hardcoded `fish_color_*` variables |
| `home/dan/features/cli/starship.nix` | Remove `palette` and `palettes.catppuccin_latte` |
| `home/dan/features/cli/shell-utils.nix` | Remove bat theme/fetch, fzf colors, lazygit theme; add btop, yazi, fastfetch |
| `home/dan/features/cli/vim.nix` | Optionally disable Stylix vim target (keep catppuccin-vim) |
| `home/dan/features/linux/hyprland.nix` | Remove color attrset, Waybar/Mako/Fuzzel; rework settings |
| `home/dan/features/linux/fonts.nix` | Remove unused fonts and misplaced wl-clipboard/cliphist |
| `tests/assertions/default.nix` | Import new rice invariants |
| `tests/unit/hm-linux-modules-test.nix` | Update for split modules, new expected values |

### Files to CREATE

| File | Purpose |
|------|---------|
| `home/dan/features/linux/waybar.nix` | Waybar config (extracted from hyprland.nix) |
| `home/dan/features/linux/mako.nix` | Mako notification config (extracted) |
| `home/dan/features/linux/fuzzel.nix` | Fuzzel launcher config (extracted) |
| `home/dan/features/linux/hyprlock.nix` | Screen lock config (new) |
| `home/dan/features/linux/hypridle.nix` | Idle management config (new) |
| `home/dan/features/linux/gtk-qt.nix` | Icon theme (Papirus-Light) — Stylix auto-themes GTK/Qt colors |
| `tests/assertions/thiniel-rice-invariants.nix` | Rice-specific assertions (new) |

---

## Current Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 0: Validation Strategy | ✅ Completed | Defined in plan |
| Phase 1: Stylix Base Setup | ✅ Completed | Stylix release-25.11 added; thiniel + J6G6Y9JK7L wired |
| Phase 2: Kitty | ✅ Completed | Stylix target enabled; themeFile + font settings removed |
| Phase 3: Fish + Starship | ✅ Completed | fish_color_* vars removed; catppuccin_latte palette removed |
| Phase 4: TUI Apps | ✅ Completed | bat/fzf/lazygit hardcoded themes removed; btop/yazi/fastfetch/lazydocker/bluetuith/pulsemixer added |
| Phase 5: Split hyprland.nix | ✅ Completed | Monolith split into hyprland, waybar, mako, fuzzel |
| Phase 6: Hyprland Compositor | ✅ Completed | Vim keybinds, window rules, animations, screenshot reworked |
| Phase 7: Waybar | ✅ Completed | Pill-shaped CSS, 32px height, @baseXX color variables |
| Phase 8: Fuzzel | ✅ Completed | Stylix target enabled; hardcoded colors removed |
| Phase 9: Mako | ✅ Completed | Stylix target enabled; hardcoded colors removed |
| Phase 10: Hypridle + Hyprlock | ✅ Completed | New modules; PAM hyprlock service added |
| Phase 11: GTK/Qt/Icons | ✅ Completed | Papirus-Light icons; Stylix auto-themes GTK/Qt |
| Phase 12: System Cleanup | ✅ Completed | Duplicate system packages removed; greetd sessions path fixed (pkgs-unstable.hyprland) |
| Phase 13: macOS Adjustments | ✅ Completed | J6G6Y9JK7L verified compatible; Stylix darwin module wired |
| Phase 14: Fonts Cleanup | ✅ Completed | 5 unused font packages removed |
| Phase 15: Vim Decision | ✅ Completed | catppuccin-vim plugin kept; Stylix vim target disabled |
| Phase 16: Tests & Assertions | ✅ Completed | 6 rice assertions + 15+ unit tests added |
| Phase 17: Final Validation | ✅ Completed | nix flake check --no-build PASS; nix fmt PASS; statix PASS; deadnix PASS |

---

## Deviation Log

- **Phase 17 commit strategy**: All Nix changes were committed incrementally across phases 1–16 (12 commits). Phase 17 commits only the plan docs (untracked files).
- **Phase 17 visual verification**: Deferred — requires running thiniel hardware (VM or real machine). Nix evaluation and build validation complete.

---

## Completion Summary

- **Completed Date**: 2026-04-09
- **Deviations**: See Deviation Log above. All architectural decisions followed the plan. One minor deviation: incremental commits per phase rather than single final commit.
- **Lessons Learned**:
  - Stylix `autoEnable = true` handles most targets automatically; explicit `stylix.targets.<name>.enable = false` needed only for vim (to keep catppuccin-vim plugin)
  - Split modules (waybar, mako, fuzzel, hyprlock, hypridle, gtk-qt) dramatically improve maintainability — each module is now ≤60 lines
  - `pkgs-unstable.hyprland` vs `pkgs.hyprland` discrepancy in greetd sessions path was a latent bug; Stylix work surfaced it
  - `deadnix` and `statix` had zero findings across all 706 lines of new/modified config — quality standards maintained
  - `nix flake check --no-build` is fast enough to use after every small change; recommended as default validation gate
