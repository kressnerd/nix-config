{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  # Container networking and volume mounting strategies (network tools consolidated in containers-common.nix)

  # Podman network configurations
  home.file.".config/containers/networks/development.json".text = builtins.toJSON {
    name = "development";
    id = "dev-network-001";
    driver = "bridge";
    network_interface = "podman-dev";
    created = "2024-01-01T00:00:00Z";
    subnets = [
      {
        subnet = "10.89.0.0/16";
        gateway = "10.89.0.1";
      }
    ];
    ipv6_enabled = false;
    internal = false;
    dns_enabled = true;
    ipam_options = {
      driver = "host-local";
    };
  };

  home.file.".config/containers/networks/isolated.json".text = builtins.toJSON {
    name = "isolated";
    id = "isolated-network-001";
    driver = "bridge";
    network_interface = "podman-iso";
    created = "2024-01-01T00:00:00Z";
    subnets = [
      {
        subnet = "10.90.0.0/16";
        gateway = "10.90.0.1";
      }
    ];
    ipv6_enabled = false;
    internal = true; # No external access
    dns_enabled = true;
    ipam_options = {
      driver = "host-local";
    };
  };

  # Volume mounting strategies for different development scenarios
  home.file.".config/containers/volumes/development-mounts.yaml".text = ''
    # Development volume mounting strategies

    # Strategy 1: Source code bind mounts (fastest, live updates)
    source_mounts:
      - type: bind
        source: "${config.home.homeDirectory}/dev"
        target: "/workspace"
        options: "rw,relatime"
        description: "Direct source code mounting for live development"

    # Strategy 2: Cached volumes (better performance on macOS)
    cached_mounts:
      - type: bind
        source: "${config.home.homeDirectory}/dev"
        target: "/workspace"
        options: "rw,cached"
        description: "Cached mounting for better macOS performance"

    # Strategy 3: Delegated volumes (best write performance)
    delegated_mounts:
      - type: bind
        source: "${config.home.homeDirectory}/dev"
        target: "/workspace"
        options: "rw,delegated"
        description: "Delegated mounting for write-heavy workloads"

    # Strategy 4: Named volumes for persistence
    named_volumes:
      - name: "node_modules"
        target: "/workspace/node_modules"
        description: "Persistent node_modules for faster installs"
      - name: "cargo_registry"
        target: "/usr/local/cargo/registry"
        description: "Shared Rust package registry"
      - name: "pip_cache"
        target: "/root/.cache/pip"
        description: "Python package cache"

    # Strategy 5: Temporary volumes for build artifacts
    temp_volumes:
      - type: tmpfs
        target: "/tmp/build"
        options: "noexec,nosuid,size=1g"
        description: "Fast temporary build directory"
  '';

  # Docker Compose networking examples
  home.file.".config/containers/examples/networking-compose.yaml".text = ''
    version: '3.8'

    # Multi-tier application with custom networking
    services:
      # Frontend service
      frontend:
        image: node:20-alpine
        container_name: dev-frontend
        working_dir: /app
        volumes:
          # Live source code mounting
          - ${config.home.homeDirectory}/dev/frontend:/app:cached
          # Persistent node_modules
          - frontend_node_modules:/app/node_modules
          # Shared assets
          - shared_assets:/app/public/assets:ro
        ports:
          - "3000:3000"
          - "3001:3001"  # Hot reload port
        environment:
          - NODE_ENV=development
          - API_URL=http://backend:8000
        networks:
          - frontend_network
          - api_network
        depends_on:
          - backend
        command: npm run dev

      # Backend API service
      backend:
        image: python:3.11-slim
        container_name: dev-backend
        working_dir: /app
        volumes:
          # Source code
          - ${config.home.homeDirectory}/dev/backend:/app:cached
          # Python cache
          - python_cache:/root/.cache/pip
          # Shared uploads
          - shared_uploads:/app/uploads
        ports:
          - "8000:8000"
          - "8001:8001"  # Debug port
        environment:
          - PYTHONPATH=/app
          - DATABASE_URL=postgresql://postgres:password@postgres:5432/devdb
          - REDIS_URL=redis://redis:6379/0
        networks:
          - api_network
          - database_network
        depends_on:
          - postgres
          - redis
        command: python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

      # Database
      postgres:
        image: postgres:15-alpine
        container_name: dev-postgres
        environment:
          - POSTGRES_USER=postgres
          - POSTGRES_PASSWORD=password
          - POSTGRES_DB=devdb
        volumes:
          # Persistent data
          - postgres_data:/var/lib/postgresql/data
          # Initialization scripts
          - ${config.home.homeDirectory}/dev/database/init:/docker-entrypoint-initdb.d:ro
          # Configuration
          - ${config.home.homeDirectory}/dev/database/postgresql.conf:/etc/postgresql/postgresql.conf:ro
        ports:
          - "5432:5432"
        networks:
          - database_network
        command: postgres -c config_file=/etc/postgresql/postgresql.conf

      # Cache
      redis:
        image: redis:7-alpine
        container_name: dev-redis
        volumes:
          - redis_data:/data
          - ${config.home.homeDirectory}/dev/redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
        ports:
          - "6379:6379"
        networks:
          - database_network
        command: redis-server /usr/local/etc/redis/redis.conf

      # Reverse proxy and load balancer
      traefik:
        image: traefik:v3.0
        container_name: dev-traefik
        command:
          - "--api.insecure=true"
          - "--providers.docker=true"
          - "--providers.docker.exposedbydefault=false"
          - "--entrypoints.web.address=:80"
          - "--entrypoints.websecure.address=:443"
        ports:
          - "80:80"
          - "443:443"
          - "8080:8080"  # Traefik dashboard
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock:ro
          - ${config.home.homeDirectory}/dev/traefik:/etc/traefik:ro
        networks:
          - frontend_network
          - traefik_network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.traefik.rule=Host(\`traefik.local\`)"

      # Development tools container
      devtools:
        image: alpine:latest
        container_name: dev-tools
        volumes:
          # Source code access
          - ${config.home.homeDirectory}/dev:/workspace:ro
          # Tool outputs
          - devtools_output:/output
        networks:
          - api_network
          - database_network
        command: tail -f /dev/null

    # Named volumes for persistence
    volumes:
      frontend_node_modules:
        driver: local
      python_cache:
        driver: local
      postgres_data:
        driver: local
      redis_data:
        driver: local
      shared_assets:
        driver: local
      shared_uploads:
        driver: local
      devtools_output:
        driver: local

    # Custom networks for service isolation
    networks:
      # Frontend network (public-facing services)
      frontend_network:
        driver: bridge
        ipam:
          config:
            - subnet: 172.20.0.0/16
              gateway: 172.20.0.1

      # API network (application services)
      api_network:
        driver: bridge
        ipam:
          config:
            - subnet: 172.21.0.0/16
              gateway: 172.21.0.1

      # Database network (backend services)
      database_network:
        driver: bridge
        internal: true  # No external access
        ipam:
          config:
            - subnet: 172.22.0.0/16
              gateway: 172.22.0.1

      # Traefik network (load balancer)
      traefik_network:
        driver: bridge
        ipam:
          config:
            - subnet: 172.23.0.0/16
              gateway: 172.23.0.1
  '';

  # Kubernetes networking example
  home.file.".config/containers/examples/k8s-networking.yaml".text = ''
    # Kubernetes networking for development

    # Namespace for isolation
    apiVersion: v1
    kind: Namespace
    metadata:
      name: dev-environment
      labels:
        environment: development

    ---
    # Network policy for service isolation
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: dev-network-policy
      namespace: dev-environment
    spec:
      podSelector:
        matchLabels:
          tier: backend
      policyTypes:
      - Ingress
      - Egress
      ingress:
      - from:
        - podSelector:
            matchLabels:
              tier: frontend
        ports:
        - protocol: TCP
          port: 8000
      egress:
      - to:
        - podSelector:
            matchLabels:
              tier: database
        ports:
        - protocol: TCP
          port: 5432

    ---
    # Service for internal communication
    apiVersion: v1
    kind: Service
    metadata:
      name: backend-service
      namespace: dev-environment
    spec:
      selector:
        app: backend
        tier: backend
      ports:
      - name: api
        port: 8000
        targetPort: 8000
      - name: debug
        port: 8001
        targetPort: 8001
      type: ClusterIP

    ---
    # Headless service for StatefulSet
    apiVersion: v1
    kind: Service
    metadata:
      name: postgres-headless
      namespace: dev-environment
    spec:
      selector:
        app: postgres
      ports:
      - port: 5432
        targetPort: 5432
      clusterIP: None

    ---
    # Ingress for external access
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: dev-ingress
      namespace: dev-environment
      annotations:
        nginx.ingress.kubernetes.io/rewrite-target: /
        nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    spec:
      rules:
      - host: dev.local
        http:
          paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 8000
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 3000
  '';

  # Shell helper functions for networking and volumes
  programs.fish = {
    shellAliases = {
      # Network management
      "pod-net-ls" = "podman network ls";
      "pod-net-inspect" = "podman network inspect";
      "pod-net-create" = "podman network create";
      "pod-net-rm" = "podman network rm";

      # Volume management
      "pod-vol-ls" = "podman volume ls";
      "pod-vol-inspect" = "podman volume inspect";
      "pod-vol-create" = "podman volume create";
      "pod-vol-prune" = "podman volume prune";

      # Network debugging
      "net-debug" = "podman run --rm -it --network";
      "net-test" = "podman run --rm nicolaka/netshoot";
    };

    interactiveShellInit = ''
      # Note: Complex bash functions kept for compatibility
      # Fish will execute these via bash -c when needed
      # Container networking helpers
      container-network-setup() {
        echo "Setting up development networks..."

        # Create development network
        podman network create development \
          --driver bridge \
          --subnet 10.89.0.0/16 \
          --gateway 10.89.0.1 \
          2>/dev/null || echo "Development network already exists"

        # Create isolated network
        podman network create isolated \
          --driver bridge \
          --subnet 10.90.0.0/16 \
          --gateway 10.90.0.1 \
          --internal \
          2>/dev/null || echo "Isolated network already exists"

        echo "Networks created successfully"
        podman network ls
      }

      container-volumes-setup() {
        echo "Setting up development volumes..."

        # Create persistent volumes
        podman volume create node_modules 2>/dev/null || true
        podman volume create python_cache 2>/dev/null || true
        podman volume create cargo_registry 2>/dev/null || true
        podman volume create postgres_data 2>/dev/null || true
        podman volume create redis_data 2>/dev/null || true

        echo "Volumes created successfully"
        podman volume ls
      }

      # Network debugging helper
      debug-container-network() {
        local container_name="$1"

        if [[ -z "$container_name" ]]; then
          echo "Usage: debug-container-network <container-name>"
          return 1
        fi

        echo "=== Container Network Debug: $container_name ==="
        echo ""

        echo "Container IP Address:"
        podman inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

        echo ""
        echo "Network Configuration:"
        podman inspect "$container_name" --format '{{json .NetworkSettings}}' | ${pkgs.jq}/bin/jq

        echo ""
        echo "Port Mappings:"
        podman port "$container_name"

        echo ""
        echo "Connected Networks:"
        podman inspect "$container_name" --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}: {{$conf.IPAddress}}{{"\n"}}{{end}}'
      }

      # Volume debugging helper
      debug-container-volumes() {
        local container_name="$1"

        if [[ -z "$container_name" ]]; then
          echo "Usage: debug-container-volumes <container-name>"
          return 1
        fi

        echo "=== Container Volume Debug: $container_name ==="
        echo ""

        echo "Volume Mounts:"
        podman inspect "$container_name" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Type}}){{"\n"}}{{end}}'

        echo ""
        echo "Volume Usage:"
        podman exec "$container_name" df -h 2>/dev/null || echo "Cannot access container filesystem"
      }

      # Performance testing for volumes
      test-volume-performance() {
        local mount_type=''${1:-bind}
        local test_dir=''${2:-/tmp/volume-test}

        echo "Testing $mount_type volume performance..."

        case "$mount_type" in
          "bind")
            podman run --rm -v "$(pwd):$test_dir:rw" alpine:latest sh -c "
              time dd if=/dev/zero of=$test_dir/test-file bs=1M count=100
              sync
              time dd if=$test_dir/test-file of=/dev/null bs=1M
              rm $test_dir/test-file
            "
            ;;
          "cached")
            podman run --rm -v "$(pwd):$test_dir:rw,cached" alpine:latest sh -c "
              time dd if=/dev/zero of=$test_dir/test-file bs=1M count=100
              sync
              time dd if=$test_dir/test-file of=/dev/null bs=1M
              rm $test_dir/test-file
            "
            ;;
          "delegated")
            podman run --rm -v "$(pwd):$test_dir:rw,delegated" alpine:latest sh -c "
              time dd if=/dev/zero of=$test_dir/test-file bs=1M count=100
              sync
              time dd if=$test_dir/test-file of=/dev/null bs=1M
              rm $test_dir/test-file
            "
            ;;
          "volume")
            podman volume create test-volume 2>/dev/null || true
            podman run --rm -v test-volume:$test_dir alpine:latest sh -c "
              time dd if=/dev/zero of=$test_dir/test-file bs=1M count=100
              sync
              time dd if=$test_dir/test-file of=/dev/null bs=1M
              rm $test_dir/test-file
            "
            podman volume rm test-volume
            ;;
        esac
      }

      # Port forwarding helper
      container-port-forward() {
        local container_name="$1"
        local host_port="$2"
        local container_port="$3"

        if [[ -z "$container_name" || -z "$host_port" || -z "$container_port" ]]; then
          echo "Usage: container-port-forward <container-name> <host-port> <container-port>"
          return 1
        fi

        podman stop "$container_name" 2>/dev/null || true
        podman run -d \
          --name "$container_name" \
          -p "$host_port:$container_port" \
          "$@"

        echo "Port forwarding: localhost:$host_port -> $container_name:$container_port"
      }
    '';
  };

  # Environment variables for networking (paths unified in containers-common.nix; keep only subnet info)
  home.sessionVariables = {
    DEV_NETWORK_SUBNET = "10.89.0.0/16";
    ISOLATED_NETWORK_SUBNET = "10.90.0.0/16";
  };

  # Networking directories created by containers-common.nix
}
