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
    ./thiniel-hardware-invariants.nix
    ./thiniel-desktop-invariants.nix
    ./thiniel-libreoffice-invariants.nix
    ./nixos-vm-minimal-invariants.nix
    ./cupix001-invariants.nix
    ./adlerkopf-invariants.nix
  ];
}
