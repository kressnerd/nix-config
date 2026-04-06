# tests/unit/default.nix
# Aggregates unit tests into a buildable derivation for flake checks
{ pkgs }:
let
  helperTests = import ./helpers-test.nix { inherit (pkgs) lib; };
  hmModuleTests = import ./hm-modules-test.nix {
    inherit (pkgs) lib;
    inherit pkgs;
  };
  allFailures = helperTests ++ hmModuleTests;
in
# lib.debug.runTests returns [] on success — the branch is selected at eval time
pkgs.runCommand "unit-tests" { } ''
  # lib.debug.runTests returns [] on success, list of failures otherwise
  ${
    if allFailures == [ ] then
      ''
        echo "All unit tests passed"
        touch $out
      ''
    else
      ''
        echo "Unit test failures: ${builtins.toJSON allFailures}"
        exit 1
      ''
  }
''
