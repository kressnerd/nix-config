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
    ./hardening.nix
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
  networking.hostName = "cupix001";
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
    cryptsetup
  ];

  # User configuration
  users.users.dan = {
    isNormalUser = true;
    description = "Daniel Kressner";
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets."users/dan/password".path;
    openssh.authorizedKeys.keys = [
      # Will be populated from secrets.yaml
    ];
  };

  # SOPS secrets management
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";
    secrets = {
      "users/dan/password" = {
        neededForUsers = true;
      };
      "headscale/noise-private-key" = {
        owner = "headscale";
        group = "headscale";
        mode = "0400";
      };
      "headscale/db-password" = {
        owner = "headscale";
        group = "headscale";
        mode = "0400";
      };
      "acme/cloudflare-dns-token" = {
        owner = "acme";
        mode = "0400";
      };
    };
  };

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      # Security hardening
      X11Forwarding = false;
      PermitUserEnvironment = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = true; # Needed for SSH tunneling
      MaxAuthTries = 3;
      MaxSessions = 10;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      # Modern crypto only
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
      ];
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
    openFirewall = true;
  };

  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      # Add your home network or trusted IPs here
    ];
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "168h"; # 1 week
      factor = "4";
    };
  };

  # Automatic security updates
  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
    flake = "github:yourusername/nix-config#cupix001";
  };

  # Enable fish system-wide
  programs.fish.enable = true;

  # Enable sudo for wheel group
  security.sudo = {
    wheelNeedsPassword = true;
    execWheelOnly = true;
  };

  # Enable systemd journal persistence
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=1G
    RuntimeMaxUse=100M
  '';
}
