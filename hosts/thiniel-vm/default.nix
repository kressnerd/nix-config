{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./home.nix
    inputs.sops-nix.nixosModules.sops
    # Note: No nixos-hardware import as this is VM-generic
    # Note: No impermanence for VM simplicity, but can be added later
  ];

  # Nix settings
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux"; # Default to Apple Silicon, can be overridden

  # Boot configuration (handled in hardware.nix)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # SOPS configuration (simplified for VM testing)
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/var/lib/sops-nix/key.txt"; # No /persist for VM

  # Basic SOPS secrets for testing
  sops.secrets.example_key = {}; # owned by root
  sops.secrets."users/test/hashed_pwd" = {
    neededForUsers = true;
  };

  # User configuration - same as thiniel but VM-optimized
  users.users = {
    dan = {
      isNormalUser = true;
      description = "Me Myself and Billie";
      initialHashedPassword = "$6$.tIb37hYTPJeB13w$RSDaCkfYIEcxNn7Isct6XxeIS8mENfhx15XjDCuSlA4xrsCwAjZZuP7vp0xTmGBOAAZoGESsG4GT8eecpTASn/";
      extraGroups = ["wheel" "networkmanager"];
    };
    test = {
      isNormalUser = true;
      description = "Non-sudo account for testing new config options that could break login.";
      hashedPasswordFile = config.sops.secrets."users/test/hashed_pwd".path;
      extraGroups = ["networkmanager"]; # No wheel for test user
    };
  };

  # Networking
  networking.hostName = "thiniel-vm";
  networking.networkmanager.enable = true;

  # Localization - same as thiniel
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # Audio - simplified for VM
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # System packages - curated subset from thiniel
  environment.systemPackages = with pkgs; [
    # System utilities (VM-appropriate subset)
    brightnessctl
    waybar
    mako
    libnotify
    kitty
    rofi

    # Essential Rust-based CLI tools (subset from thiniel)
    fzf
    eza
    fd
    ripgrep
    bat
    lsd
    delta
    ouch
    macchina
    sd
    procs
    zoxide

    # Directory and disk usage tools
    dust
    duf

    # Other useful tools for VM testing
    skim
    starship
    bottom
    tokei
    jql
    hexyl
  ];

  # Programs - same as thiniel
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  programs.git.enable = true;
  programs.fuse.userAllowOther = true;

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Display manager and Hyprland - key feature from thiniel
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "dan";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs.hyprland}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # Hyprland - using unstable like thiniel
  programs.hyprland.enable = true;
  programs.hyprland.package = pkgs-unstable.hyprland;

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22]; # SSH
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # System state version
  system.stateVersion = "25.11";
}
