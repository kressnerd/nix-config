# tests/unit/hm-macos-modules-test.nix
# Characterization unit tests for home/dan/features/macos/* modules.
# All tests capture existing behavior and must pass against the current codebase.
{ lib }:
let
  # defaults.nix uses `_:` so it accepts any argument set (including empty)
  defaultsModule = import ../../home/dan/features/macos/defaults.nix { };
  aerospaceModule = import ../../home/dan/features/macos/aerospace.nix { };
  nsGlobal = defaultsModule.targets.darwin.defaults.NSGlobalDomain;
  dock = defaultsModule.targets.darwin.defaults."com.apple.dock";
  finder = defaultsModule.targets.darwin.defaults."com.apple.finder";
in
lib.debug.runTests {

  # ── AeroSpace ────────────────────────────────────────────────────────────────
  testAerospaceUsesSettingsNotUserSettings = {
    expr = aerospaceModule.programs.aerospace ? settings;
    expected = true;
  };

  # ── NSGlobalDomain ───────────────────────────────────────────────────────────
  testDarwinNSGlobalDomainExists = {
    expr = defaultsModule.targets.darwin.defaults ? NSGlobalDomain;
    expected = true;
  };

  testDarwinAccentColorGraphite = {
    expr = nsGlobal.AppleAccentColor;
    expected = -1;
  };

  testDarwinKeyboardUIMode = {
    expr = nsGlobal.AppleKeyboardUIMode;
    expected = 3;
  };

  testDarwinPressAndHoldDisabled = {
    expr = nsGlobal.ApplePressAndHoldEnabled;
    expected = false;
  };

  # ── Dock ─────────────────────────────────────────────────────────────────────
  testDockOrientationLeft = {
    expr = dock.orientation;
    expected = "left";
  };

  testDockAutohide = {
    expr = dock.autohide;
    expected = true;
  };

  testDockShowRecentsDisabled = {
    expr = dock."show-recents";
    expected = false;
  };

  testDockTilesize = {
    expr = dock.tilesize;
    expected = 48;
  };

  # ── Finder ───────────────────────────────────────────────────────────────────
  testFinderShowAllExtensions = {
    expr = finder.AppleShowAllExtensions;
    expected = true;
  };

  testFinderShowPathbar = {
    expr = finder.ShowPathbar;
    expected = true;
  };

  testFinderListView = {
    expr = finder.FXPreferredViewStyle;
    expected = "Nlsv";
  };
}
