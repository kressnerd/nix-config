# tests/unit/host-template-test.nix
# The host scaffold in templates/host/ is copied for every new host. Its
# stateVersion must match the release channel this flake builds against,
# otherwise a fresh host starts out pinned to a previous release.
# Deriving the expectation from lib.trivial.release makes this test fail on
# every channel bump, forcing the template to be updated deliberately.
{ lib, pkgs }:
let
  template = builtins.readFile ../../templates/host/default.nix;
  expected = "system.stateVersion = \"${pkgs.lib.trivial.release}\";";
in
lib.debug.runTests {
  testHostTemplateStateVersionMatchesChannel = {
    expr = lib.strings.hasInfix expected template;
    expected = true;
  };
}
