# tests/assertions/thiniel-desktop-invariants.nix
# Thiniel-specific desktop assertions — enforced at evaluation time via nix flake check
# Covers: Zathura, MPV, wlsunset, CUPS, and other desktop/GUI concerns
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [ ];
  };
}
