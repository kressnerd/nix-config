{
  config,
  pkgs,
  lib,
  ...
}: {
  # Common container/devcontainers/Kubernetes tooling consolidated here to eliminate duplication
  home.packages = with pkgs; [
    # Core runtime + build tools
    podman
    podman-compose
    buildah
    skopeo

    # Inspection / management
    ctop
    dive
    lazydocker
    crane

    # Kubernetes toolchain
    kubectl
    k9s
    kind

    # Networking + debugging
    nettools
    netcat

    # Security / supply chain
    grype
    syft
    cosign

    # Higher-level build tooling
    nixpacks
  ];

  # Unified environment variables (used by other feature modules)
  home.sessionVariables = {
    CONTAINER_DEV_ROOT = "${config.home.homeDirectory}/containers";
    CONTAINER_DEV_CONFIG = "${config.home.homeDirectory}/.config/containers";
    CONTAINER_DEV_TEMPLATES = "${config.home.homeDirectory}/.config/containers/templates";
    NIX_CONTAINER_TEMPLATES = "${config.home.homeDirectory}/.config/nix-containers/templates";

    # Podman config paths (referenced in podman module scripts)
    CONTAINERS_CONF = "${config.home.homeDirectory}/.config/containers/containers.conf";
    CONTAINERS_STORAGE_CONF = "${config.home.homeDirectory}/.config/containers/storage.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.home.homeDirectory}/.config/containers/registries.conf";

    # Compose defaults
    COMPOSE_PROJECT_NAME = "dev-env";
    COMPOSE_FILE = "docker-compose.yml";
  };

  # Shared Fish aliases (avoid duplication across modules)
  programs.fish.shellAliases = {
    # Podman compatibility
    docker = "podman";
    docker-compose = "podman-compose";

    # Podman shortcuts
    prun = "podman run --rm -it";
    pexec = "podman exec -it";
    plogs = "podman logs -f";

    # Cleanup & maintenance
    container-cleanup = "podman system prune -af && podman volume prune -f";
    container-reset = "podman system reset";

    # High-level container security helpers
    scan-image = "grype";
    sign-image = "cosign sign";
    verify-image = "cosign verify";

    # Kubernetes shortcuts (generic)
    k = "kubectl";
    kdebug = "kubectl run debug --rm -i --tty --image=busybox -- sh";
  };

  # Unified directory creation (replaces per-module activation DAG entries)
  home.activation.containerCommonDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.local/bin"

    # Core container config tree
    mkdir -p "${config.home.homeDirectory}/.config/containers"/{environments,networks,volumes,templates,examples}

    # Podman storage locations
    mkdir -p "${config.home.homeDirectory}/.local/share/containers/storage"

    # Devcontainer templates
    mkdir -p "${config.home.homeDirectory}/.config/devcontainers"/{nodejs,python,rust}

    # Nix container templates
    mkdir -p "${config.home.homeDirectory}/.config/nix-containers/templates"
  '';

  # Minimal helper functions (generic only; specialized ones stay in their modules)
  programs.fish.functions = {
    # Generic container environment status
    container-env-status = ''
      echo "=== Container Environment Status ==="
      echo "Running containers:"
      podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
      echo
      echo "Networks:"
      podman network ls
      echo
      echo "Volumes:"
      podman volume ls
    '';

    # Generic volume setup (specialized networking remains in networking module)
    container-common-volumes = ''
      podman volume create node_modules 2>/dev/null; or true
      podman volume create python_cache 2>/dev/null; or true
      podman volume create cargo_registry 2>/dev/null; or true
      podman volume create postgres_data 2>/dev/null; or true
      podman volume create redis_data 2>/dev/null; or true
    '';
  };
}
