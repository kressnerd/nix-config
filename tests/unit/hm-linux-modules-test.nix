# tests/unit/hm-linux-modules-test.nix
# Characterization unit tests for Home Manager Linux feature modules.
# Captures existing behaviour as-is so any regression is immediately visible.
# Covers: impermanence.nix, gnome-keyring.nix, fonts.nix, hyprland.nix
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

  # hyprland.nix — signature is `{ pkgs, ... }:`
  hyprlandModule = import ../../home/dan/features/linux/hyprland.nix { inherit pkgs; };
  hyprSettings = hyprlandModule.wayland.windowManager.hyprland.settings;
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

  testImpermanenceHasKeepassxc = {
    expr = builtins.elem ".config/keepassxc" impermanenceDirs;
    expected = true;
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
    expected = 16;
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

  testFontsHasWlClipboard = {
    expr = builtins.elem "wl-clipboard" fontsPkgNames;
    expected = true;
  };

  testFontsHasCliphist = {
    expr = builtins.elem "cliphist" fontsPkgNames;
    expected = true;
  };

  testFontsPackageCount = {
    expr = builtins.length fontsModule.home.packages;
    expected = 7;
  };

  # ── hyprland ──────────────────────────────────────────────────────────────

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
    expected = 35;
  };

  testHyprlandBindeCount = {
    expr = builtins.length hyprSettings.binde;
    expected = 4;
  };

  testHyprlandActiveBorderColor = {
    expr = hyprSettings.general."col.active_border";
    expected = "rgb(7287fd)";
  };

  # ── waybar ────────────────────────────────────────────────────────────────

  testWaybarEnabled = {
    expr = hyprlandModule.programs.waybar.enable;
    expected = true;
  };

  testWaybarSystemdEnabled = {
    expr = hyprlandModule.programs.waybar.systemd.enable;
    expected = true;
  };

  # ── mako ─────────────────────────────────────────────────────────────────

  testMakoEnabled = {
    expr = hyprlandModule.services.mako.enable;
    expected = true;
  };

  testMakoBgColor = {
    expr = hyprlandModule.services.mako.settings.background-color;
    expected = "#eff1f5";
  };

  # ── rofi ──────────────────────────────────────────────────────────────────

  testRofiEnabled = {
    expr = hyprlandModule.programs.rofi.enable;
    expected = true;
  };

  testRofiShowIcons = {
    expr = hyprlandModule.programs.rofi.extraConfig.show-icons;
    expected = true;
  };
}
