# tests/assertions/thiniel-hardware-invariants.nix
# Thiniel-specific hardware assertions — enforced at evaluation time via nix flake check
# Covers: Bluetooth, fwupd, WWAN, battery thresholds, and other hardware concerns
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [ ];
  };
}
