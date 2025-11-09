{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  # Podman-based containerized development environment
  home.packages = with pkgs; [
    # Core Podman stack only
    podman # Main container runtime
    podman-compose # Docker Compose compatibility
    buildah # OCI image building tool
    skopeo # Container image operations
  ];

  # Podman configuration
  home.file.".config/containers/containers.conf".text = ''
    [containers]
    # Use cgroups v2 for better resource management
    cgroups = "enabled"

    # Default capabilities for containers
    default_capabilities = [
      "CHOWN",
      "DAC_OVERRIDE",
      "FOWNER",
      "FSETID",
      "KILL",
      "NET_BIND_SERVICE",
      "SETFCAP",
      "SETGID",
      "SETPCAP",
      "SETUID",
      "SYS_CHROOT"
    ]

    # Default sysctls
    default_sysctls = [
      "net.ipv4.ping_group_range=0 0",
    ]

    # Timezone in containers
    tz = "local"

    [engine]
    # Container engine settings
    cgroup_manager = "systemd"
    runtime = "crun"

    # Network settings

    # Storage settings
    driver = "overlay"

    [network]
    # Network backend
    network_backend = "netavark"

    [secrets]
    driver = "file"
  '';

  # Podman network configuration
  home.file.".config/containers/networks/podman-default.json".text = builtins.toJSON {
    name = "podman-default";
    id = "2f259bab93aaaaa2542ba43ef33eb990d0999ee1b9924b557b7be53c0b7a1bb9";
    driver = "bridge";
    network_interface = "podman0";
    created = "2023-01-01T00:00:00Z";
    subnets = [
      {
        subnet = "10.88.0.0/16";
        gateway = "10.88.0.1";
      }
    ];
    ipv6_enabled = false;
    internal = false;
    dns_enabled = true;
    ipam_options = {
      driver = "dhcp";
    };
  };

  # Storage configuration for Podman
  home.file.".config/containers/storage.conf".text = ''
    [storage]
    driver = "overlay"
    runroot = "${config.home.homeDirectory}/.local/share/containers/run"
    graphroot = "${config.home.homeDirectory}/.local/share/containers/storage"

    [storage.options]
    additionalimagestores = []

    [storage.options.overlay]
    mountopt = "nodev,metacopy=on"

  '';

  # Registries configuration
  home.file.".config/containers/registries.conf".text = ''
    # v2 format for registries.conf
    # Search registries
    [[registry]]
    location = "docker.io"
    [[registry]]
    location = "quay.io"
    [[registry]]
    location = "ghcr.io"

    # Insecure registries (none by default)
    # [[registry]]
    # location = "my.insecure.registry:5000"
    # insecure = true

    # Blocked registries (none by default)
    # [[registry]]
    # location = "bad.registry.com"
    # blocked = true

    # Mirror for docker.io
    [[registry]]
    location = "docker.io"
    [[registry.mirror]]
    location = "mirror.gcr.io"
  '';

  # Shell integration and aliases
  programs.zsh = {
    shellAliases = {
      # Podman aliases with Docker compatibility
      "docker" = "podman";
      "docker-compose" = "podman-compose";

      # Podman shortcuts
      "prun" = "podman run --rm -it";
      "pexec" = "podman exec -it";
      "plogs" = "podman logs -f";

      # Container development shortcuts (using podman directly)
      "dev-ubuntu" = "podman run -it --name dev-ubuntu ubuntu:22.04 /bin/bash";
      "dev-fedora" = "podman run -it --name dev-fedora fedora:latest /bin/bash";
      "dev-arch" = "podman run -it --name dev-arch archlinux:latest /bin/bash";

      # Container cleanup
      "container-cleanup" = "podman system prune -af && podman volume prune -f";
      "container-reset" = "podman system reset";
    };

    initContent = ''
      # Podman completion
      if command -v podman &> /dev/null; then
        source <(podman completion zsh)
      fi

      # Development container shortcuts
      dev-enter() {
        local container_name=''${1:-dev-ubuntu}
        podman exec -it "$container_name" /bin/bash
      }

      dev-create() {
        local name=''${1:-dev-env}
        local image=''${2:-ubuntu:22.04}
        podman run -d --name "$name" \
          --volume "${config.home.homeDirectory}/dev:/host-dev:rw" \
          --volume "${config.home.homeDirectory}/.ssh:/host-ssh:ro" \
          "$image" sleep infinity
      }
    '';
  };

  # Environment variables for Podman
  home.sessionVariables = {
    # Podman configuration
    CONTAINERS_CONF = "${config.home.homeDirectory}/.config/containers/containers.conf";
    CONTAINERS_STORAGE_CONF = "${config.home.homeDirectory}/.config/containers/storage.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.home.homeDirectory}/.config/containers/registries.conf";

    # Docker compatibility
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";

    # Development environment paths
    CONTAINER_DEV_ROOT = "${config.home.homeDirectory}/containers";
  };

  # Create container development directories
  home.activation.createContainerDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/containers"
    mkdir -p "${config.home.homeDirectory}/.local/share/containers/storage"
    mkdir -p "${config.home.homeDirectory}/.config/containers/networks"
  '';
}
