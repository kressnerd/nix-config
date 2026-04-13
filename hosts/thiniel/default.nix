{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ../common/optional/virtualisation.nix
    ../common/optional/networkmanager.nix
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ../../modules/nixos/systemd-sleep-settings.nix
    ../../tests/assertions
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/root_vg/root /btrfs_tmp
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
  };

  # SOPS configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/persist/system/var/lib/sops-nix/key.txt";

    secrets = {
      example_key = { }; # owned by root
      "myservice/user_dir/my_secret" = {
        mode = "0440";
        inherit (config.users.users.dan) group;

        # restart/reload systemd unit on secret change
        #    restartUnits = [ "home-assistant.service" ]; # there is also a reloadUnit

        # Symlinks to other directories
        #    path = "/var/lib/hass/secrets.yaml";
      };
      "myservice/my_subdir/my_secret" = {
        owner = config.users.users.dan.name;
      };
      "users/test/hashed_pwd" = {
        neededForUsers = true;
      };
    };
  };

  # Fish shell — must be enabled at system level for it to work as a login shell
  programs.fish.enable = true;

  # User configuration
  users.groups.libvirtd.members = [ "dan" ];
  users.users = {
    dan = {
      description = "Me Myself and Billie";
      shell = pkgs.fish;
      initialHashedPassword = "$6$.tIb37hYTPJeB13w$RSDaCkfYIEcxNn7Isct6XxeIS8mENfhx15XjDCuSlA4xrsCwAjZZuP7vp0xTmGBOAAZoGESsG4GT8eecpTASn/";
    };
    test = {
      isNormalUser = true;
      description = "Non-sudo account for testing new config options that could break login.";
      hashedPasswordFile = config.sops.secrets."users/test/hashed_pwd".path;
      # initialHashedPassword = "$6$HzSnxWKrApkhTofZ$oLQL5ibjJWYR9ur4Bf56Ln5/bYZyETa526cESY2X.quTXYg4cMaJ.oLeG1ihV2LdYOPdX13IZ.O1ysfjV8gj2/";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
  };

  # File system configuration
  fileSystems = {
    "/".options = [
      "compress=zstd"
      "noatime"
    ];
    "/persist" = {
      options = [
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
  };

  # Impermanence system directories
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/cups"
      "/var/lib/nixos" # contains important state
      "/var/lib/containers" # Podman container images and layers (system-level)
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      #      "/etc/mullvad-vpn"
      #      "/var/cache/libvirt"
      #      "/var/cache/mullvad-vpn"
      "/var/lib/fwupd"
      "/var/lib/ModemManager"
      "/var/cache/tuigreet"
      #      "/var/lib/OpenRGB"
      #      "/var/lib/alsa"
      #      "/var/lib/docker"
      #      "/var/lib/libvirt"
      #      "/var/lib/systemd"
      #      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      #      "/var/lib/logrotate.status"
      "/var/lib/sops-nix/key.txt"
      #      { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
  };

  # Networking
  networking.hostName = "thiniel";
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  # WWAN modem support — NetworkManager may enable ModemManager implicitly,
  # but explicit declaration ensures it is always active and persisted.
  networking.modemmanager.enable = true;
  # TODO: Mullvad VPN — intentionally not configured; evaluate when needed

  # Fix sops key permissions so home-manager (user dan) can read it
  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0750 root wheel -"
    "z /var/lib/sops-nix/key.txt 0640 root wheel -"
  ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Localization
  time.hardwareClockInLocalTime = true; # For Windows dual boot
  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Services
  services = {
    # File system maintenance
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" ];
    };

    # Power management
    # Disable TLP — auto-cpufreq is used instead; nixos-hardware enables TLP by default
    tlp.enable = false;
    thermald.enable = true;
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
          enable_thresholds = "true";
          start_threshold = 20;
          stop_threshold = 80;
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    # Enable the X11 windowing system.
    # xserver.enable = true;

    # Configure keymap in X11
    # xserver.xkb.layout = "us";
    # xserver.xkb.options = "eurosign:e,caps:escape";

    # Enable CUPS to print documents.
    printing.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Enable sound.
    # hardware.pulseaudio.enable = true;
    # OR

    # Audio
    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # libinput.enable = true;

    openssh.enable = true;

    # Firmware updates via LVFS (ThinkPad X270 supports fwupd)
    fwupd.enable = true;

    # D-Bus Secret Service for credential storage (VS Code, etc.)
    gnome.gnome-keyring.enable = true;

    # GVFS D-Bus service — required for trash (VS Code, GTK apps)
    gvfs.enable = true;

    greetd = {
      enable = true;
      useTextGreeter = true; # Clear boot messages from login TTY
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${pkgs-unstable.hyprland}/share/wayland-sessions";
          user = "greeter";
        };
      };
    };
  };

  # PAM integration: auto-unlock gnome-keyring on greetd/tuigreet password login
  security.pam.services.greetd.enableGnomeKeyring = true;

  # PAM integration: required for Hyprlock to authenticate via PAM
  security.pam.services.hyprlock = { };

  # Hardware
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Power management
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  # OPAL SED FDE: lid close must not suspend — encryption key is lost on sleep/hibernate
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # OPAL SED FDE: disable all sleep states — encryption key is lost on sleep/hibernate
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  environment = {
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    # System packages
    systemPackages = with pkgs; [
      # Rust-based CLI tools
      lsd # fancy ls like exa
      diffr # diff with colors
      difftastic # slow colorfull diff
      ouch # com-/decompress everything
      macchina # system information
      sd # sed clone
      xcp # extended cp
      rm-improved # rm clone
      #rargs # deprecated:  awk and xargs clone with pattern matching
      runiq # remove duplicate lines from input

      # Rust directory and disk usage tools
      diskus # disk usage info
      dutree # du clone
      dua # du clone

      # Rust other tools
      skim # fzf clone
      topgrade # upgrade everything
      bingrep # binary grep
      broot # interactive tree
      dupe-krill # file deduplicator
      ruplacer # find and replace
      fastmod # find and replace
      genact # activity generator
      grex # regx builder
      bandwhich # bandwith monitor
      ffsend # firefox send file from cli
      pastel # color info
      miniserve # mini http server
      monolith # bundle a webpage in a single file
      tealdeer # tldr clone to read man pages
      tokei # code statistics

      # Data handling
      jql # JSON
      # xsv # deprecated CSV
      xan # CSV
      hexyl # HEX viewer

      #   wget
      #   alacrity
      #   sl
    ];

    # UWSM requires hyprland.desktop in XDG_DATA_DIRS for session discovery
    # Workaround for nixpkgs#485123: services.displayManager not enabled with greetd
    sessionVariables.XDG_DATA_DIRS = [
      "${pkgs-unstable.hyprland}/share"
    ];
  };

  # Programs
  programs = {
    vim = {
      enable = true;
      defaultEditor = true;
    };
    git.enable = true;
    fuse.userAllowOther = true;
    seahorse.enable = true; # GUI for gnome-keyring management

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    # mtr.enable = true;
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };

    # Hyprland
    hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
      withUWSM = true;
      # portalPackage is typically not needed when using pkgs-unstable.hyprland
    };
  };

  # Podman container runtime
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # HM aliases handle docker → podman mapping
    defaultNetwork.settings.dns_enabled = true;
  };

  # OCI containers (Podman backend)
  virtualisation.oci-containers = {
    backend = "podman";
    containers.qdrant_roo = {
      image = "docker.io/qdrant/qdrant:latest";
      ports = [ "6333:6333" ];
      volumes = [ "qdrant_storage:/qdrant/storage" ];
      autoStart = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # --- Stylix: system-wide Catppuccin Latte theming ---
  # autoEnable = false: HM feature modules already have hand-crafted Catppuccin Latte
  # theming; Stylix HM targets are enabled selectively to avoid conflicts.
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    image = pkgs.nixos-artwork.wallpapers.catppuccin-latte.gnomeFilePath;
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 11;
        popups = 11;
      };
    };
    cursor = {
      package = pkgs.catppuccin-cursors.latteBlue;
      name = "catppuccin-latte-blue-cursors";
      size = 24;
    };
  };

  # TODO(2026-04): Backup solution — evaluate restic or borgbackup for automated backups
  # ownCloud provides sync but not versioned backup
  # Priority: important but deferred — create tracking issue when ready

  system.stateVersion = "25.11";
}
