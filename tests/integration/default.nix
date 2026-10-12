# tests/integration/default.nix
# Aggregates integration tests for the flake checks output
# Each test is a pkgs.testers.runNixOSTest derivation (Linux-only)
{
  pkgs,
  home-manager-unstable,
  sops-nix,
  ...
}:
{
  integration-vm-minimal-ssh = import ./nixos-vm-minimal-test.nix { inherit pkgs; };
  integration-adlerkopf = import ./adlerkopf-test.nix { inherit pkgs; };
  integration-ssh-identity-selection = import ./ssh-identity-selection-test.nix {
    inherit pkgs sops-nix;
    home-manager = home-manager-unstable;
  };
  integration-private-data-separation = import ./private-data-separation-test.nix {
    inherit pkgs;
  };
}
