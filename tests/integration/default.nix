# tests/integration/default.nix
# Aggregates integration tests for the flake checks output
# Each test is a pkgs.testers.runNixOSTest derivation (Linux-only)
{ pkgs, ... }:
{
  integration-vm-minimal-ssh = import ./nixos-vm-minimal-test.nix { inherit pkgs; };
}
