# tests/assertions/default.nix
# Aggregates assertion test modules for import into host configurations
{
  imports = [
    ./host-invariants.nix
    ./thiniel-invariants.nix
    ./common-global-invariants.nix
    ./thiniel-services-invariants.nix
    ./thiniel-impermanence-invariants.nix
    ./thiniel-rice-invariants.nix
    ./thiniel-sleep-invariants.nix
    ./thiniel-keyboard-invariants.nix
    ./nixos-vm-minimal-invariants.nix
  ];
}
