{ config, pkgs, ... }:

{
  # Disable nix-darwin's Nix management (required for Determinate Nix)
  nix.enable = false;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility, please read the changelog before changing
  system.stateVersion = 6;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # User configuration
  users.users."daniel.kressner" = {
    name = "daniel.kressner";
    home = "/Users/daniel.kressner";
  };

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."daniel.kressner" = import ./home.nix;
  };
}
