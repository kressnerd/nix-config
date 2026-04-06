# tests/unit/hm-modules-test.nix
# Unit tests for Home Manager module values in home/dan/thiniel.nix
# Phase 4 RED — F-002 (nrb alias) and F-003 (--use-remote-sudo in remote aliases)
# Phase 5 RED — F-004 (go and uv must NOT be in shell-utils.nix)
# Phase 6 RED — F-005 (kitty keybindings must be platform-appropriate)
# Phase 7 RED — F-007 (SSH UseKeychain must NOT be present on Linux)
{ lib, pkgs }:
let
  # Import the thiniel HM profile — call with {} since signature is { ... }:
  # Returns the raw attrset { imports, home, sops, programs, ... } without
  # invoking the module system, so programs.fish.shellAliases is a plain attrset.
  thinielModule = import ../../home/dan/thiniel.nix { };

  aliases = thinielModule.programs.fish.shellAliases;

  # Import shell-utils module with real pkgs to inspect home.packages.
  # shell-utils.nix has signature { pkgs, ... }: and returns an attrset with home.packages.
  shellUtilsModule = import ../../home/dan/features/cli/shell-utils.nix { inherit pkgs; };
  shellUtilsPkgNames = builtins.map (p: p.pname or p.name or "") shellUtilsModule.home.packages;
in
lib.debug.runTests {
  # ── F-002: nrb local alias must exist ────────────────────────────────────

  # RED: thiniel.nix has no `nrb` key — expects true, expr returns false → FAIL
  testNrbAliasExists = {
    expr = builtins.hasAttr "nrb" aliases;
    expected = true;
  };

  # ── F-003: Remote aliases must contain --use-remote-sudo ─────────────────

  # RED: nrs-remote value lacks --use-remote-sudo → FAIL
  testNrsRemoteHasUseRemoteSudo = {
    expr = lib.strings.hasInfix "--use-remote-sudo" aliases.nrs-remote;
    expected = true;
  };

  # RED: nrt-remote value lacks --use-remote-sudo → FAIL
  testNrtRemoteHasUseRemoteSudo = {
    expr = lib.strings.hasInfix "--use-remote-sudo" aliases.nrt-remote;
    expected = true;
  };

  # RED: nrb-remote value lacks --use-remote-sudo → FAIL
  testNrbRemoteHasUseRemoteSudo = {
    expr = lib.strings.hasInfix "--use-remote-sudo" aliases.nrb-remote;
    expected = true;
  };

  # ── F-004: go and uv must NOT be in shell-utils.nix home.packages ─────────

  # RED: go is currently in shell-utils.nix → expects true (not present), expr returns false → FAIL
  testGoNotInShellUtils = {
    expr = !(builtins.elem "go" shellUtilsPkgNames);
    expected = true;
  };

  # RED: uv is currently in shell-utils.nix → expects true (not present), expr returns false → FAIL
  testUvNotInShellUtils = {
    expr = !(builtins.elem "uv" shellUtilsPkgNames);
    expected = true;
  };

  # ── F-005: Kitty keybindings must be platform-appropriate ─────────────────

  # RED: current kitty.nix always emits cmd+ keys regardless of platform → FAIL on Linux
  testKittyLinuxNoCmd = {
    expr =
      let
        mockPkgsLinux = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = false;
            isLinux = true;
          };
        };
        kittyModule = import ../../home/dan/features/cli/kitty.nix { pkgs = mockPkgsLinux; };
        keybindingKeys = builtins.attrNames kittyModule.programs.kitty.keybindings;
      in
      !(builtins.any (k: lib.strings.hasPrefix "cmd+" k) keybindingKeys);
    expected = true;
  };

  # PASS: current kitty.nix uses cmd+ which is correct for Darwin
  testKittyDarwinUsesCmd = {
    expr =
      let
        mockPkgsDarwin = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = true;
            isLinux = false;
          };
        };
        kittyModule = import ../../home/dan/features/cli/kitty.nix { pkgs = mockPkgsDarwin; };
        keybindingKeys = builtins.attrNames kittyModule.programs.kitty.keybindings;
      in
      builtins.any (k: lib.strings.hasPrefix "cmd+" k) keybindingKeys;
    expected = true;
  };

  # ── F-007: SSH UseKeychain must only be present on macOS ──────────────────

  # RED: current ssh.nix uses `_:` and always sets UseKeychain regardless of
  # platform → expects true (not present on Linux), expr returns false → FAIL
  testSshLinuxNoUseKeychain = {
    expr =
      let
        mockPkgsLinux = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = false;
            isLinux = true;
          };
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix { pkgs = mockPkgsLinux; };
        extraOpts = sshModule.programs.ssh.matchBlocks."*".extraOptions;
      in
      !(builtins.hasAttr "UseKeychain" extraOpts);
    expected = true;
  };

  # F-NEW-003: UseKeychain must be present on Darwin (macOS)
  testSshDarwinHasUseKeychain = {
    expr =
      let
        mockPkgsDarwin = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = true;
            isLinux = false;
          };
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix { pkgs = mockPkgsDarwin; };
        extraOpts = sshModule.programs.ssh.matchBlocks."*".extraOptions;
      in
      builtins.hasAttr "UseKeychain" extraOpts;
    expected = true;
  };
}
