# tests/assertions/J6G6Y9JK7L-darwin-invariants.nix
# Darwin-level (nix-darwin system) invariants for J6G6Y9JK7L.
# The HM-level file tests/assertions/J6G6Y9JK7L-invariants.nix cannot see
# nix-darwin system options such as `homebrew.*`, hence this second module.
{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.homebrew.onActivation.cleanup == "zap";
      message = "J6G6Y9JK7L: homebrew.onActivation.cleanup must be \"zap\", got ${config.homebrew.onActivation.cleanup}";
    }
    {
      assertion = config.homebrew.onActivation.extraFlags == [ ];
      message = "J6G6Y9JK7L: homebrew.onActivation.extraFlags must be empty — nix-darwin 26.05 emits --zap --force-cleanup for cleanup = \"zap\" itself";
    }
  ];
}
