# tests/unit/hm-modules-test.nix
# Unit tests for Home Manager module values in home/dan/thiniel.nix
# Phase 4 RED — F-002 (nrb alias) and F-003 (--use-remote-sudo in remote aliases)
{ lib }:
let
  # Import the thiniel HM profile — call with {} since signature is { ... }:
  # Returns the raw attrset { imports, home, sops, programs, ... } without
  # invoking the module system, so programs.fish.shellAliases is a plain attrset.
  thinielModule = import ../../home/dan/thiniel.nix { };

  aliases = thinielModule.programs.fish.shellAliases;
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
}
