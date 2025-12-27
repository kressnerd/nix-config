{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
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
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  documentation.nixos.enable = false;

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # RAID configuration
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "MAILADDR root";

  # Initrd networking for remote unlock
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [
        "/etc/secrets/initrd/ssh_host_rsa_key"
        "/etc/secrets/initrd/ssh_host_ed25519_key"
      ];
      authorizedKeys = config.users.users.dan.openssh.authorizedKeys.keys;
    };
  };

  # SOPS configuration
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/persist/system/var/lib/sops-nix/key.txt";

  # Hostname
  networking.hostName = "pronix";

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

  # Impermanence configuration
  boot.initrd.postDeviceCommands = pkgs.lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/pool/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;

  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
      "/var/lib/sops-nix/key.txt"
    ];
  };

  # User configuration
  users.users.dan = {
    isNormalUser = true;
    description = "Dan";
    extraGroups = ["networkmanager" "wheel" "sudo"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEWvGgnlCq6l+ObGMVLLs34CP0vEX+Edf7sx6/3BvDpQ pronix"
    ];
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    cryptsetup
    btrfs-progs
    smartmontools # Disk health monitoring
    mdadm # RAID management
  ];

  # Server Maintenance
  services.fstrim.enable = true; # Essential for NVMe
  services.smartd.enable = true; # Monitor disk health
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = ["/"];
  };

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
    allowedTCPPorts = [22];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;
}
