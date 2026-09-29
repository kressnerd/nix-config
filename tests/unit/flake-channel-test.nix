# tests/unit/flake-channel-test.nix
# Guards the nixpkgs release channel pinned in flake.nix.
# Fails loudly if the flake input drifts away from the expected stable release.
{ lib, pkgs }:
lib.debug.runTests {
  testNixpkgsReleaseIs2605 = {
    expr = pkgs.lib.trivial.release;
    expected = "26.05";
  };
}
