# tests/unit/nixfmt-alias-test.nix
# nixpkgs 26.05 turned `nixfmt-rfc-style` into a warnAlias for `nixfmt`.
# Every .nix file must use the attribute `nixfmt` directly, otherwise evaluation
# emits "nixfmt-rfc-style is now the same as pkgs.nixfmt" on each build.
# Uses readFile + hasInfix because these modules need a full module system eval.
{ lib }:
let
  files = [
    ../../flake.nix
    ../../home/dan/features/development/formatters.nix
    ../../home/dan/features/productivity/emacs-doom.nix
    ../../tests/assertions/J6G6Y9JK7L-invariants.nix
  ];
  offenders = builtins.filter (
    f: lib.strings.hasInfix "nixfmt-rfc-style" (builtins.readFile f)
  ) files;
in
lib.debug.runTests {
  testNoNixfmtRfcStyleAlias = {
    expr = offenders;
    expected = [ ];
  };
}
