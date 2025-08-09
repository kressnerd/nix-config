{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x270
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
  ];

  # Nix settings
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    experimental-features = ["nix-command" "flakes"];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # SOPS configuration
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/persist/system/var/lib/sops-nix/key.txt";

  sops.secrets.example_key = {}; # owned by root
  sops.secrets."myservice/user_dir/my_secret" = {
    mode = "0440";
    group = config.users.users.dan.group;
  };
  sops.secrets."myservice/my_subdir/my_secret" = {
    owner = config.users.users.dan.name;
  };
  sops.secrets."users/test/hashed_pwd" = {
    neededForUsers = true;
  };

  # User configuration
  users.groups.libvirtd.members = ["dan"];
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
      extraGroups = ["wheel" "networkmanager"];
    };
  };

  # Impermanence configuration - automatic btrfs root reset
  boot.initrd.postDeviceCommands = lib.mkAfter ''
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

  # File system configuration
  fileSystems = {
    "/".options = ["compress=zstd" "noatime"];
    "/persist".options = ["compress=zstd" "noatime"];
    "/nix".options = ["compress=zstd" "noatime"];
  };
  fileSystems."/persist".neededForBoot = true;

  # Impermanence system directories
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

  # Virtualization
  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;

  # Networking
  networking.hostName = "thiniel";
  networking.networkmanager.enable = true;

  # Localization
  time.timeZone = "Europe/Berlin";
  time.hardwareClockInLocalTime = true; # For Windows dual boot
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "de_DE.UTF-8";
  };

  # File system maintenance
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = ["/"];
  };

  # Power management
  powerManagement.enable = true;
  powerManagement.powertop.enable = true;
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersafe";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # System utilities
    brightnessctl
    waybar
    mako
    libnotify
    kitty
    rofi-wayland

    # Rust-based CLI tools (from original config)
    fzf
    eza # fancy ls like lsd
    fd # modern find
    ripgrep # modern grep
    bat # cat with syntax highlighting
    lsd # fancy ls like exa
    diffr # diff with colors
    delta # diff for git
    difftastic # slow colorfull diff
    ouch # com-/decompress everything
    macchina # system information
    sd # sed clone
    procs # modern ps clone
    xcp # extended cp
    rm-improved # rm clone
    runiq # remove duplicate lines from input
    zoxide # better cd

    # Rust directory and disk usage tools
    dust # du clone
    diskus # disk usage info
    dutree # du clone
    duf # df alt
    dua # du clone

    # Rust other tools
    skim # fzf clone
    starship # shell prompt
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
    bottom # top clone
    tokei # code statistics

    # Data handling
    jql # JSON
    xan # CSV
    hexyl # HEX viewer
  ];

  # Programs
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  programs.git.enable = true;
  programs.fuse.userAllowOther = true;

  # Services
  services.openssh.enable = true;
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

  # Hyprland
  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  programs.hyprland.portalPackage = inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;

  # State version
  system.stateVersion = "25.05";
}
