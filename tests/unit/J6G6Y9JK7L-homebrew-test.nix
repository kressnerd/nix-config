# tests/unit/J6G6Y9JK7L-homebrew-test.nix
# Unit test asserting that the marta cask is present in hosts/J6G6Y9JK7L/default.nix.
# Uses readFile + hasInfix because the host module references config.nix-homebrew.taps
# and cannot be imported as a raw attrset without a full module system evaluation.
# Asserts the marta cask is declared in hosts/J6G6Y9JK7L/default.nix.
{ lib }:
let
  hostFileContent = builtins.readFile ../../hosts/J6G6Y9JK7L/default.nix;
in
lib.debug.runTests {
  testMartaCaskPresent = {
    expr = lib.strings.hasInfix "\"marta\"" hostFileContent;
    expected = true;
  };
}
