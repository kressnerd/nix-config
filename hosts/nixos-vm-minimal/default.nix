{pkgs, ...}: {
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./disko.nix
    ./home.nix
  ];

  # System Configuration
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "aarch64-linux";

  # Nix configuration (host-specific: gc and store optimisation)
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Boot configuration is handled in hardware.nix

  # Hostname
  networking.hostName = "nixos-vm-minimal";

  # Internationalization (host-specific extra locales)
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    gnumake
    # LUKS utilities
    cryptsetup
  ];

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22]; # SSH
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
}
