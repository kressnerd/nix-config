{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./nginx.nix
    ./headscale.nix
    ./firewall.nix
    ./impermanence.nix
    ./home.nix
    inputs.sops-nix.nixosModules.sops
  ];

  # System Configuration
  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      # Security: restrict Nix daemon
      allowed-users = ["@wheel"];
      trusted-users = ["root" "@wheel"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Hostname
  networking.hostName = "cupix001-vm";
  networking.domain = "kressner.cloud";

  # Enable NetworkManager
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "Europe/Berlin";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
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

  # Minimal essential packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tmux
  ];

  # User configuration
  users.users.dan = {
    isNormalUser = true;
    description = "Daniel Kressner";
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.fish;
    # VM testing: use simple password instead of hashed
    password = "test"; # ONLY FOR VM TESTING
  };

  # SOPS secrets management (disabled for VM)
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    # Secrets disabled for VM testing
  };

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # VM testing only
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      # Modern crypto only
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
      ];
    };
    openFirewall = true;
  };

  # Fail2ban disabled for VM testing
  # services.fail2ban.enable = false;

  # Automatic security updates disabled for VM
  system.autoUpgrade.enable = false;

  # Enable fish system-wide
  programs.fish.enable = true;

  # Enable sudo for wheel group (no password for VM)
  security.sudo = {
    wheelNeedsPassword = false;
  };

  # Enable systemd journal persistence
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=1G
    RuntimeMaxUse=100M
  '';

  # Disable hardening features for VM testing
  security.lockKernelModules = false;
  security.apparmor.enable = false;
  security.auditd.enable = false;
}
