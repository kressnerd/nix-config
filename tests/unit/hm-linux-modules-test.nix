# tests/unit/hm-linux-modules-test.nix
# Characterization unit tests for Home Manager Linux feature modules.
# Captures existing behaviour as-is so any regression is immediately visible.
# Covers: impermanence.nix, gnome-keyring.nix, fonts.nix,
#         hyprland.nix, waybar.nix, mako.nix, fuzzel.nix,
#         hyprlock.nix, hypridle.nix, gtk-qt.nix
#
# NOTE: hyprland/waybar/mako/fuzzel/hyprlock/hypridle/gtk-qt tests are Linux-only
# (pkgs.hyprland, pkgs.fuzzel etc. are unsupported on Darwin). They are gated with
# pkgs.stdenv.isLinux so the aarch64-darwin unit-helpers check continues to pass.
{ lib, pkgs }:
let
  # impermanence.nix — signature is `_:`, call with empty attrset
  impermanenceModule = import ../../home/dan/features/linux/impermanence.nix { };
  impermanenceDirs = impermanenceModule.home.persistence."/persist".directories;
  impermanenceFiles = impermanenceModule.home.persistence."/persist".files;

  # gnome-keyring.nix — signature is `_:`, call with empty attrset
  gnomeKeyringModule = import ../../home/dan/features/linux/gnome-keyring.nix { };

  # fonts.nix — signature is `{ pkgs, ... }:`
  fontsModule = import ../../home/dan/features/linux/fonts.nix { inherit pkgs; };
  fontsPkgNames = builtins.map (p: p.pname or p.name or "") fontsModule.home.packages;

  # hyprland/waybar/mako/fuzzel/hyprlock/hypridle/gtk-qt — Linux only
  # Wrapped so Darwin evaluation never touches Linux-only packages.
  hyprlandTests =
    if pkgs.stdenv.isLinux then
      let
        hyprlandModule = import ../../home/dan/features/linux/hyprland.nix { inherit pkgs; };
        waybarModule = import ../../home/dan/features/linux/waybar.nix { inherit pkgs; };
        makoModule = import ../../home/dan/features/linux/mako.nix { };
        fuzzelModule = import ../../home/dan/features/linux/fuzzel.nix { };
        hyprideModule = import ../../home/dan/features/linux/hypridle.nix { };
        hyprlockModule = import ../../home/dan/features/linux/hyprlock.nix { inherit lib; };
        gtkQtModule = import ../../home/dan/features/linux/gtk-qt.nix { inherit pkgs; };
        hyprSettings = hyprlandModule.wayland.windowManager.hyprland.settings;
        hyprPkgNames = builtins.map (p: p.pname or p.name or "") hyprlandModule.home.packages;
        waybarPkgNames = builtins.map (p: p.pname or p.name or "") waybarModule.home.packages;
      in
      lib.debug.runTests {

        # ── hyprland ──────────────────────────────────────────────────────────

        testHyprlandEnabled = {
          expr = hyprlandModule.wayland.windowManager.hyprland.enable;
          expected = true;
        };

        testHyprlandMainMod = {
          expr = hyprSettings."$mainMod";
          expected = "SUPER";
        };

        testHyprlandMonitorCount = {
          expr = builtins.length hyprSettings.monitor;
          expected = 4;
        };

        testHyprlandWorkspaceCount = {
          expr = builtins.length hyprSettings.workspace;
          expected = 10;
        };

        testHyprlandBindCount = {
          expr = builtins.length hyprSettings.bind;
          expected = 36;
        };

        testHyprlandBindeCount = {
          expr = builtins.length hyprSettings.binde;
          expected = 4;
        };

        testHyprlandGapsIn = {
          expr = hyprSettings.general.gaps_in;
          expected = 4;
        };

        testHyprlandRounding = {
          expr = hyprSettings.decoration.rounding;
          expected = 8;
        };

        # ── waybar ──────────────────────────────────────────────────────────

        testWaybarEnabled = {
          expr = waybarModule.programs.waybar.enable;
          expected = true;
        };

        testWaybarSystemdEnabled = {
          expr = waybarModule.programs.waybar.systemd.enable;
          expected = true;
        };

        testWaybarHasSettings = {
          expr = waybarModule.programs.waybar.settings ? mainBar;
          expected = true;
        };

        testWaybarHeight = {
          expr = waybarModule.programs.waybar.settings.mainBar.height;
          expected = 32;
        };

        testWaybarHasCustomPowerModule = {
          expr = waybarModule.programs.waybar.settings.mainBar ? "custom/power";
          expected = true;
        };

        testWaybarCustomPowerHasOnClick = {
          expr = waybarModule.programs.waybar.settings.mainBar."custom/power" ? "on-click";
          expected = true;
        };

        # ── rofi-power-menu (now in waybar.nix) ─────────────────────────────

        testWaybarHasRofiPowerMenu = {
          expr = builtins.elem "rofi-power-menu" waybarPkgNames;
          expected = true;
        };

        # ── mako ────────────────────────────────────────────────────────────

        testMakoEnabled = {
          expr = makoModule.services.mako.enable;
          expected = true;
        };

        testMakoMaxVisible = {
          expr = makoModule.services.mako.settings.max-visible;
          expected = 3;
        };

        # ── fuzzel ──────────────────────────────────────────────────────────

        testFuzzelEnabled = {
          expr = fuzzelModule.programs.fuzzel.enable;
          expected = true;
        };

        testFuzzelHasMainSettings = {
          expr = fuzzelModule.programs.fuzzel.settings ? main;
          expected = true;
        };

        testFuzzelWidth = {
          expr = fuzzelModule.programs.fuzzel.settings.main.width;
          expected = 35;
        };

        testFuzzelIconsEnabled = {
          expr = fuzzelModule.programs.fuzzel.settings.main.icons-enabled;
          expected = "no";
        };

        # ── hyprlock ─────────────────────────────────────────────────────────

        testHyprlockEnabled = {
          expr = hyprlockModule.programs.hyprlock.enable;
          expected = true;
        };

        testHyprlockHideCursor = {
          expr = hyprlockModule.programs.hyprlock.settings.general.hide_cursor;
          expected = true;
        };

        testHyprlockGrace = {
          expr = hyprlockModule.programs.hyprlock.settings.general.grace;
          expected = 5;
        };

        # ── hypridle ─────────────────────────────────────────────────────────

        testHypridleEnabled = {
          expr = hyprideModule.services.hypridle.enable;
          expected = true;
        };

        testHypridleListenerCount = {
          expr = builtins.length hyprideModule.services.hypridle.settings.listener;
          expected = 3;
        };

        testHypridleLockCmd = {
          expr = hyprideModule.services.hypridle.settings.general.lock_cmd;
          expected = "pidof hyprlock || hyprlock";
        };

        # ── gtk-qt ───────────────────────────────────────────────────────────

        testGtkEnabled = {
          expr = gtkQtModule.gtk.enable;
          expected = true;
        };

        testGtkIconThemeName = {
          expr = gtkQtModule.gtk.iconTheme.name;
          expected = "Papirus-Light";
        };

        testQtEnabled = {
          expr = gtkQtModule.qt.enable;
          expected = true;
        };

        # ── hyprland: power keybinding ───────────────────────────────────────

        testHyprlandHasPowerKeybinding = {
          expr = builtins.any (b: lib.strings.hasInfix "rofi-power-menu" b) hyprSettings.bind;
          expected = true;
        };

        # ── hyprland: rofi-power-menu in hyprland packages ───────────────────

        testHyprlandHasRofiPowerMenu = {
          expr = builtins.elem "rofi-power-menu" hyprPkgNames;
          expected = true;
        };
      }
    else
      [ ]; # skip all hyprland tests on Darwin
in
lib.debug.runTests {

  # ── impermanence: mount point ─────────────────────────────────────────────

  testImpermanenceMountPointExists = {
    expr = impermanenceModule.home.persistence ? "/persist";
    expected = true;
  };

  # ── impermanence: directories ─────────────────────────────────────────────

  testImpermanenceHasMesaShaderCache = {
    expr = builtins.elem ".cache/mesa_shader_cache" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasMesaShaderCacheDb = {
    expr = builtins.elem ".cache/mesa_shader_cache_db" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasCacheMozilla = {
    expr = builtins.elem ".cache/mozilla" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasClaude = {
    expr = builtins.elem ".claude" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasMozilla = {
    expr = builtins.elem ".mozilla" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasSsh = {
    expr = builtins.elem ".ssh" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasVscodeExtensions = {
    expr = builtins.elem ".vscode/extensions" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasDev = {
    expr = builtins.elem "dev" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasProjects = {
    expr = builtins.elem "Projects" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasSopsAge = {
    expr = builtins.elem ".config/sops/age" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasVscodeConfig = {
    expr = builtins.elem ".config/Code" impermanenceDirs;
    expected = true;
  };

  testImpermanenceDoesNotHaveKeepassxc = {
    expr = builtins.elem ".config/keepassxc" impermanenceDirs;
    expected = false;
  };

  testImpermanenceHasOwnCloud = {
    expr = builtins.elem ".config/ownCloud" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasOwnCloudShare = {
    expr = builtins.elem ".local/share/ownCloud" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasKeyrings = {
    expr = builtins.elem ".local/share/keyrings" impermanenceDirs;
    expected = true;
  };

  testImpermanenceHasSweethome = {
    expr = builtins.elem ".eteks" impermanenceDirs;
    expected = true;
  };

  testImpermanenceDirCount = {
    expr = builtins.length impermanenceDirs;
    expected = 15;
  };

  # ── impermanence: files ───────────────────────────────────────────────────

  testImpermanenceHasBashHistory = {
    expr = builtins.elem ".bash_history" impermanenceFiles;
    expected = true;
  };

  testImpermanenceFileCount = {
    expr = builtins.length impermanenceFiles;
    expected = 1;
  };

  # ── gnome-keyring ─────────────────────────────────────────────────────────

  testGnomeKeyringEnabled = {
    expr = gnomeKeyringModule.services.gnome-keyring.enable;
    expected = true;
  };

  testGnomeKeyringComponents = {
    expr = gnomeKeyringModule.services.gnome-keyring.components;
    expected = [ "secrets" ];
  };

  testGnomeKeyringComponentCount = {
    expr = builtins.length gnomeKeyringModule.services.gnome-keyring.components;
    expected = 1;
  };

  # ── fonts ─────────────────────────────────────────────────────────────────

  testFontsFontconfigEnabled = {
    expr = fontsModule.fonts.fontconfig.enable;
    expected = true;
  };

  testFontsHasFontAwesome = {
    expr = builtins.elem "font-awesome" fontsPkgNames;
    expected = true;
  };

  testFontsHasSymbolsOnly = {
    expr = builtins.elem "nerd-fonts-symbols-only" fontsPkgNames;
    expected = true;
  };

  testFontsPackageCount = {
    expr = builtins.length fontsModule.home.packages;
    expected = 2;
  };

}
++ hyprlandTests
