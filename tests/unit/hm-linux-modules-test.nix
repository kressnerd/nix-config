# tests/unit/hm-linux-modules-test.nix
# Characterization unit tests for Home Manager Linux feature modules.
# Captures existing behaviour as-is so any regression is immediately visible.
# Covers: gnome-keyring.nix, fonts.nix,
#         hyprland.nix, waybar.nix, mako.nix, fuzzel.nix,
#         hyprlock.nix, hypridle.nix, gtk-qt.nix
#
# NOTE: hyprland/waybar/mako/fuzzel/hyprlock/hypridle/gtk-qt tests are Linux-only
# (pkgs.hyprland, pkgs.fuzzel etc. are unsupported on Darwin). They are gated with
# pkgs.stdenv.hostPlatform.isLinux so the aarch64-darwin unit-helpers check continues to pass.
{ lib, pkgs }:
let
  normalizeModule =
    module:
    if module ? _type && module._type == "merge" then
      lib.foldl' lib.recursiveUpdate { } (
        builtins.map (
          m: if m ? _type && m._type == "if" then if m.condition then m.content else { } else m
        ) module.contents
      )
    else
      module;

  # gnome-keyring.nix — signature is `{ config, lib, pkgs, ... }:`, pass pkgs for libsecret
  # config mock: persistence disabled so home.persistence block is a no-op
  gnomeKeyringModule = normalizeModule (
    import ../../home/dan/features/linux/gnome-keyring.nix {
      inherit lib pkgs;
      config.myHome.persistence = {
        enable = false;
        root = "/persist";
      };
    }
  );
  gnomeKeyringPkgNames = builtins.map (p: p.pname or p.name or "") gnomeKeyringModule.home.packages;

  # fonts.nix — signature is `{ pkgs, ... }:`
  fontsModule = import ../../home/dan/features/linux/fonts.nix { inherit pkgs; };
  fontsPkgNames = builtins.map (p: p.pname or p.name or "") fontsModule.home.packages;

  # hyprland/waybar/mako/fuzzel/hyprlock/hypridle/gtk-qt — Linux only
  # Wrapped so Darwin evaluation never touches Linux-only packages.
  hyprlandTests =
    if pkgs.stdenv.hostPlatform.isLinux then
      let
        hyprlandModule = normalizeModule (
          import ../../home/dan/features/linux/hyprland.nix {
            inherit pkgs lib;
            pkgs-unstable = pkgs;
            config.myHome.persistence = {
              enable = false;
              root = "/persist";
            };
          }
        );
        waybarModule = import ../../home/dan/features/linux/waybar.nix {
          inherit pkgs;
          pkgs-unstable = pkgs;
        };
        makoModule = import ../../home/dan/features/linux/mako.nix { };
        fuzzelModule = import ../../home/dan/features/linux/fuzzel.nix { };
        hyprideModule = import ../../home/dan/features/linux/hypridle.nix { };
        hyprlockModule = import ../../home/dan/features/linux/hyprlock.nix { inherit lib; };
        gtkQtModule = import ../../home/dan/features/linux/gtk-qt.nix { inherit pkgs; };
        hyprSettings = hyprlandModule.wayland.windowManager.hyprland.settings;
        bindArgs = b: b._args or [ ];
        bindHasKey =
          key: builtins.any (b: bindArgs b != [ ] && builtins.head (bindArgs b) == key) hyprSettings.bind;
        bindHasText =
          text: builtins.any (b: lib.strings.hasInfix text (builtins.toJSON b)) hyprSettings.bind;
        bindIsRepeating =
          key:
          builtins.any (
            b:
            let
              args = bindArgs b;
            in
            builtins.length args >= 3
            && builtins.head args == key
            && ((builtins.elemAt args 2).repeating or false)
          ) hyprSettings.bind;
        hyprPkgNames = builtins.map (p: p.pname or p.name or "") hyprlandModule.home.packages;
        waybarPkgNames = builtins.map (p: p.pname or p.name or "") waybarModule.home.packages;
      in
      lib.debug.runTests {

        # ── hyprland ──────────────────────────────────────────────────────────

        testHyprlandEnabled = {
          expr = hyprlandModule.wayland.windowManager.hyprland.enable;
          expected = true;
        };

        testHyprlandHasEdpMonitor = {
          expr = builtins.any (m: (m.output or "") == "eDP-1") hyprSettings.monitor;
          expected = true;
        };

        testHyprlandHasCatchAllMonitor = {
          expr = builtins.any (m: (m.output or null) == "") hyprSettings.monitor;
          expected = true;
        };

        testHyprlandHasWorkspaceBind = {
          expr = bindHasKey "SUPER + 1";
          expected = true;
        };

        testHyprlandHasTerminalBind = {
          expr = bindHasText "kitty";
          expected = true;
        };

        testHyprlandHasScreenshotBind = {
          expr = bindHasText "grim";
          expected = true;
        };

        testHyprlandHasVolumeDownRepeatingBind = {
          expr = bindIsRepeating "XF86AudioLowerVolume";
          expected = true;
        };

        testHyprlandHasBrightnessDownRepeatingBind = {
          expr = bindIsRepeating "XF86MonBrightnessDown";
          expected = true;
        };

        testHyprlandNoWindowrulev2 = {
          expr = !(hyprSettings ? windowrulev2);
          expected = true;
        };

        testHyprlandHasFloatDialogWindowrule = {
          expr = builtins.any (r: r.name == "float-dialog") hyprSettings.window_rule;
          expected = true;
        };

        testHyprlandHasPinPipWindowrule = {
          expr = builtins.any (r: r.name == "pin-pip") hyprSettings.window_rule;
          expected = true;
        };

        testHyprlandHasIdleinhibitFullWindowrule = {
          expr = builtins.any (r: r.name == "idleinhibit-full") hyprSettings.window_rule;
          expected = true;
        };

        testHyprlandNoDeprecatedIdleinhibit = {
          expr = builtins.any (rule: rule ? idleinhibit) hyprSettings.window_rule;
          expected = false;
        };

        testHyprlandGapsIn = {
          expr = hyprSettings.config.general.gaps_in;
          expected = 2;
        };

        testHyprlandRounding = {
          expr = hyprSettings.config.decoration.rounding;
          expected = 8;
        };

        testHyprlandNoStaticWorkspace = {
          expr = !(hyprSettings ? workspace);
          expected = true;
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

        # 26.05 renamed `systemd.target` (string) to `systemd.targets` (list).
        testWaybarUsesSystemdTargets = {
          expr = waybarModule.programs.waybar.systemd.targets or null;
          expected = [ "hyprland-session.target" ];
        };

        testWaybarNoDeprecatedSystemdTarget = {
          expr = waybarModule.programs.waybar.systemd ? target;
          expected = false;
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

        testHypridleHasScreenDimListener = {
          expr = builtins.any (
            l: lib.strings.hasInfix "brightnessctl" l."on-timeout"
          ) hyprideModule.services.hypridle.settings.listener;
          expected = true;
        };

        testHypridleHasLockListener = {
          expr = builtins.any (
            l: lib.strings.hasInfix "loginctl lock-session" l."on-timeout"
          ) hyprideModule.services.hypridle.settings.listener;
          expected = true;
        };

        testHypridleHasDpmsOffListener = {
          expr = builtins.any (
            l: lib.strings.hasInfix "dpms off" l."on-timeout"
          ) hyprideModule.services.hypridle.settings.listener;
          expected = true;
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
          expr = bindHasText "rofi-power-menu";
          expected = true;
        };

        # ── hyprland: rofi-power-menu in hyprland packages ───────────────────

        testHyprlandHasRofiPowerMenu = {
          expr = builtins.elem "rofi-power-menu" hyprPkgNames;
          expected = true;
        };

        testHyprlandGestureIsSet = {
          expr = hyprSettings.gesture or null;
          expected = {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          };
        };

        testHyprlandStartHookIsList = {
          expr = builtins.isList hyprSettings.on;
          expected = true;
        };
      }
    else
      [ ]; # skip all hyprland tests on Darwin
in
lib.debug.runTests {

  # ── gnome-keyring ─────────────────────────────────────────────────────────

  testGnomeKeyringEnabled = {
    expr = gnomeKeyringModule.services.gnome-keyring.enable;
    expected = true;
  };

  testGnomeKeyringComponents = {
    expr = gnomeKeyringModule.services.gnome-keyring.components;
    expected = [ "secrets" ];
  };

  testGnomeKeyringHasLibsecret = {
    expr = builtins.elem "libsecret" gnomeKeyringPkgNames;
    expected = true;
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

}
++ hyprlandTests
