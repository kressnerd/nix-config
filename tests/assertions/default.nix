# tests/assertions/default.nix
# Aggregates assertion test modules for import into host configurations
{
  imports = [
    ./host-invariants.nix
    ./thiniel-invariants.nix
  ];
}
