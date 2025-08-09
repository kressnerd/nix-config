{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  home = {
    stateVersion = "25.05";

    # Common packages for all hosts
    packages = with pkgs; [
      htop
      ripgrep
    ];
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # SOPS configuration for Linux hosts
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    # Note: defaultSopsFile should be set per-host in the host-specific configuration
  };
}
