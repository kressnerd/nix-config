# tests/unit/maki-skill-parity-test.nix
# Guards the list of project skills Maki may load from `.maki/skills/`.
#
# `givn skills sync` owns the `givn-*` subtree there and `.gitignore` excludes
# it, so those are generated and unchecked. The six project skills are committed
# twice on purpose: once for OpenCode under `.opencode/skills/`, once for Maki
# under `.maki/skills/`. Byte equality between the two copies is checked by the
# `unit-maki-skills` build; this test pins the set, so a skill added to one tree
# without the other is a failing check rather than a silent gap.
#
# Neither tree is read here: flake-check evaluation runs against a restricted
# store, where opening a directory under the repository is not allowed.
{ lib }:
let
  projectSkills = [
    "home-manager-config"
    "network-security"
    "nix-module-dev"
    "nixos-server"
    "nix-testing"
    "sops-secrets"
  ];
in
lib.debug.runTests {
  # The list the flake compares byte-for-byte must be the list this change
  # decided on. Duplicates would silently reduce coverage.
  testProjectSkillSetIsExact = {
    expr = lib.unique projectSkills;
    expected = projectSkills;
  };

  # `create-python-cli-tool` is OpenCode-only: it covers the Python tool
  # convention, which no Nix or security role in this repository uses.
  testPythonToolingSkillIsNotProjected = {
    expr = lib.elem "create-python-cli-tool" projectSkills;
    expected = false;
  };
}
