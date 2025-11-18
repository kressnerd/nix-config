{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  # Nix-specific containerization tools and workflows (packages moved to containers-common.nix)

  # Nix flake template for containerized applications
  home.file.".config/nix-containers/templates/webapp-flake.nix".text = ''
    {
      description = "Simple containerized application with Nix";

      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
      };

      outputs = { self, nixpkgs, flake-utils }:
        flake-utils.lib.eachDefaultSystem (system: {
          devShells.default = nixpkgs.legacyPackages.''${system}.mkShell {
            buildInputs = with nixpkgs.legacyPackages.''${system}; [
              nodejs_20
              podman
              skopeo
            ];

            shellHook = "echo 'Nix development environment ready!'";
          };
        });
    }
  '';

  # Docker Compose with Nix services
  home.file.".config/nix-containers/templates/compose-with-nix.yaml".text = ''
    version: '3.8'

    services:
      # Application built with Nix
      app:
        build:
          context: .
          dockerfile: Dockerfile.nix
        ports:
          - "3000:3000"
        environment:
          - NODE_ENV=development
        volumes:
          - ./src:/app/src:ro
          - ./public:/app/public:ro
        depends_on:
          - postgres
          - redis

      # PostgreSQL with Nix-managed configuration
      postgres:
        image: postgres:15-alpine
        environment:
          POSTGRES_DB: devdb
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: password
        volumes:
          - postgres_data:/var/lib/postgresql/data
          - ./nix/postgres-init.sql:/docker-entrypoint-initdb.d/init.sql:ro
        ports:
          - "5432:5432"

      # Redis
      redis:
        image: redis:7-alpine
        volumes:
          - redis_data:/data
        ports:
          - "6379:6379"

      # Nginx reverse proxy (Nix-configured)
      nginx:
        build:
          context: ./nix/nginx
          dockerfile: Dockerfile
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - ./nix/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
          - ./nix/nginx/ssl:/etc/nginx/ssl:ro
        depends_on:
          - app

    volumes:
      postgres_data:
      redis_data:

    networks:
      default:
        driver: bridge
  '';

  # Nix-based Dockerfile template
  home.file.".config/nix-containers/templates/Dockerfile.nix".text = ''
    # Multi-stage Dockerfile using Nix
    FROM nixos/nix:latest AS builder

    # Enable flakes and add cache
    RUN echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf && \
        echo 'substituters = https://cache.nixos.org https://nix-community.cachix.org' >> /etc/nix/nix.conf && \
        echo 'trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=' >> /etc/nix/nix.conf

    # Copy source
    WORKDIR /src
    COPY . .

    # Build the application
    RUN nix build .#webapp

    # Runtime stage
    FROM scratch

    # Copy the built application and its dependencies
    COPY --from=builder /nix/store /nix/store
    COPY --from=builder /src/result /app

    # Set up environment
    ENV PATH="/app/bin:/nix/store/*/bin"
    EXPOSE 3000

    # Run the application
    ENTRYPOINT ["/app/bin/webapp"]
  '';

  # Kubernetes deployment template using Nix
  home.file.".config/nix-containers/templates/k8s-deployment.yaml".text = ''
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nix-webapp
      labels:
        app: nix-webapp
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nix-webapp
      template:
        metadata:
          labels:
            app: nix-webapp
        spec:
          containers:
          - name: webapp
            image: nix-webapp:latest
            ports:
            - containerPort: 3000
            env:
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: webapp-secrets
                  key: database-url
            resources:
              requests:
                memory: "128Mi"
                cpu: "100m"
              limits:
                memory: "256Mi"
                cpu: "200m"
            livenessProbe:
              httpGet:
                path: /health
                port: 3000
              initialDelaySeconds: 30
              periodSeconds: 10
            readinessProbe:
              httpGet:
                path: /ready
                port: 3000
              initialDelaySeconds: 5
              periodSeconds: 5
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nix-webapp-service
    spec:
      selector:
        app: nix-webapp
      ports:
      - protocol: TCP
        port: 80
        targetPort: 3000
      type: ClusterIP
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: nix-webapp-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: letsencrypt-prod
    spec:
      tls:
      - hosts:
        - webapp.example.com
        secretName: webapp-tls
      rules:
      - host: webapp.example.com
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nix-webapp-service
                port:
                  number: 80
  '';

  # Shell integration and helper scripts
  programs.fish = {
    shellAliases = {
      # Nix container building
      "nix-build-container" = "nix build .#container";
      "nix-load-container" = "podman load < result";
      "nix-run-container" = "podman run --rm -it";

      # Development workflows
      "dev-nix" = "nix develop";
      "dev-flake" = "nix develop .#";

      # Container security scanning
      "scan-image" = "grype";
      "sign-image" = "cosign sign";
      "verify-image" = "cosign verify";

      # Kubernetes shortcuts
      "k" = "kubectl";
      "kx" = "kubectx";
      "kns" = "kubens";
      "kdebug" = "kubectl run debug --rm -i --tty --image=busybox -- sh";
    };

    interactiveShellInit = ''
      # Note: Complex bash functions kept for compatibility
      # Fish will execute these via bash -c when needed
      # Nix container helper functions
      nix-container-build() {
        local flake_ref=''${1:-.}
        local attr=''${2:-container}

        echo "Building container with Nix..."
        nix build "''${flake_ref}#''${attr}"

        if [[ -L result ]]; then
          echo "Container built successfully!"
          echo "Load with: podman load < result"
          echo "Inspect with: skopeo inspect docker-archive:result"
        fi
      }

      nix-container-run() {
        local image_name="$1"
        shift
        local args=("$@")

        if [[ -z "$image_name" ]]; then
          echo "Usage: nix-container-run <image-name> [podman-args...]"
          return 1
        fi

        podman run --rm -it "''${args[@]}" "$image_name"
      }

      nix-dev-container() {
        local template=''${1:-webapp}
        local project_name=''${2:-$(basename $(pwd))}

        local template_dir="${config.home.homeDirectory}/.config/nix-containers/templates"

        if [[ ! -f "$template_dir/$template-flake.nix" ]]; then
          echo "Template $template not found. Available templates:"
          ls "$template_dir"/*-flake.nix 2>/dev/null | xargs -n1 basename -s -flake.nix | sed 's/^/  /'
          return 1
        fi

        cp "$template_dir/$template-flake.nix" ./flake.nix
        cp "$template_dir/compose-with-nix.yaml" ./docker-compose.yml 2>/dev/null || true
        cp "$template_dir/Dockerfile.nix" ./Dockerfile 2>/dev/null || true

        echo "Created Nix containerized project template: $template"
        echo "Next steps:"
        echo "  nix develop          # Enter development shell"
        echo "  nix build .#container # Build container image"
        echo "  podman-compose up    # Start development stack"
      }

      # Kubernetes development helper
      k8s-nix-deploy() {
        local namespace=''${1:-default}
        local image_tag=''${2:-latest}

        # Build container
        nix build .#container

        # Load into podman
        podman load < result

        # Tag for deployment
        local image_name=$(podman images --format "{{.Repository}}:{{.Tag}}" | head -n1)
        podman tag "$image_name" "localhost:5000/$(basename $(pwd)):$image_tag"

        # Push to local registry (if running)
        if podman ps --format "{{.Names}}" | grep -q registry; then
          podman push "localhost:5000/$(basename $(pwd)):$image_tag"
        fi

        # Apply Kubernetes manifests
        if [[ -f k8s-deployment.yaml ]]; then
          kubectl apply -f k8s-deployment.yaml -n "$namespace"
          echo "Deployed to Kubernetes namespace: $namespace"
        fi
      }

      # Container cleanup with Nix awareness
      container-cleanup-nix() {
        echo "Cleaning up containers and Nix build results..."

        # Clean up podman
        podman system prune -af

        # Clean up Nix build results
        find . -name "result*" -type l -delete 2>/dev/null || true

        # Clean up Nix store (careful!)
        echo "Run 'nix-collect-garbage -d' to clean up Nix store"
      }
    '';
  };

  # Environment variables (template path unified in containers-common.nix)
  home.sessionVariables = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
  };

  # Template directory creation handled by containers-common.nix
}
