# tests/unit/default.nix
# Aggregates unit tests into a buildable derivation for flake checks
{ pkgs }:
let
  helperTests = import ./helpers-test.nix { inherit (pkgs) lib; };
in
# lib.debug.runTests returns [] on success — the branch is selected at eval time
pkgs.runCommand "unit-helpers" { } ''
  # lib.debug.runTests returns [] on success, list of failures otherwise
  ${
    if helperTests == [ ] then
      ''
        echo "All unit tests passed"
        touch $out
      ''
    else
      ''
        echo "Unit test failures: ${builtins.toJSON helperTests}"
        exit 1
      ''
  }
''
