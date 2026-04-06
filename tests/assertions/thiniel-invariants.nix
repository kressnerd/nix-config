# tests/assertions/thiniel-invariants.nix
# Thiniel-specific NixOS module assertions — enforced at evaluation time via nix flake check
# Guarded by hostname to avoid failures on other hosts that import tests/assertions
{ config, pkgs, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.programs.fish.enable;
        message = "Thiniel invariant violated: programs.fish.enable must be true (required for fish as login shell)";
      }
      {
        assertion = config.users.users.dan.shell == pkgs.fish;
        message = "Thiniel invariant violated: users.users.dan.shell must be set to pkgs.fish";
      }
    ];
  };
}
