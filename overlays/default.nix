# Default overlay aggregator for the nix-config repository
# This file combines all individual overlays into a single overlay function
#
# Usage in flake.nix:
#   nixpkgs.overlays = [ (import ./overlays) ];
#
# Individual overlays should be placed in subdirectories and imported here
final: prev:
{
  # Import all overlay modules
  # Each overlay should export a function that takes final/prev and returns an attrset

  # Skip check phase: fish test gets SIGKILL'd on the remote builder (Killed: 9)
  direnv = prev.direnv.overrideAttrs (_old: {
    doCheck = false;
  });
}
// (import ./vscode-extensions final prev)
