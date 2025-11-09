{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  # Main container development configuration - imports all container features
  imports = [
    ./containers-common.nix # Consolidated shared tooling/env
    ./containers-podman.nix # Core Podman setup
    ./containers-vscode.nix # VS Code dev container integration
    ./containers-nix-tools.nix # Nix-specific container tools
    ./containers-networking.nix # Networking and volume strategies
  ];

  # Packages moved to containers-common.nix (deduplicated)

  # Unified container environment script
  home.file.".local/bin/container-dev" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Container development environment manager
      SCRIPT_DIR="$(dirname "$(realpath "$0")")"
      CONFIG_DIR="${config.home.homeDirectory}/.config/containers"

      usage() {
        cat << EOF
      Container Development Environment Manager

      USAGE:
          container-dev <command> [options]

      COMMANDS:
          setup                   Initial setup of container environment
          init <template>         Initialize project with container template
          start <env>            Start development environment
          stop <env>             Stop development environment
          status                 Show status of all containers
          clean                  Clean up containers and volumes
          network                Manage container networks
          volume                 Manage container volumes
          logs <container>       Show container logs
          shell <container>      Open shell in container
          build                  Build containers with Nix
          deploy                 Deploy to Kubernetes
          help                   Show this help message

      TEMPLATES:
          nodejs                 Node.js development environment
          python                 Python development environment
          rust                   Rust development environment
          fullstack              Full-stack web application
          microservices          Microservices architecture

      EXAMPLES:
          container-dev setup                    # Initial setup
          container-dev init nodejs myapp       # Create Node.js project
          container-dev start nodejs-dev        # Start Node.js environment
          container-dev build                   # Build with Nix
          container-dev deploy k8s              # Deploy to Kubernetes

      EOF
      }

      setup_environment() {
        echo "🚀 Setting up container development environment..."

        # Create necessary directories
        mkdir -p "$CONFIG_DIR"/{environments,networks,volumes,templates,examples}

        # Setup Podman networks
        echo "📡 Setting up container networks..."
        podman network create development --subnet 10.89.0.0/16 2>/dev/null || echo "Development network exists"
        podman network create isolated --subnet 10.90.0.0/16 --internal 2>/dev/null || echo "Isolated network exists"

        # Setup persistent volumes
        echo "💾 Setting up container volumes..."
        podman volume create node_modules 2>/dev/null || echo "node_modules volume exists"
        podman volume create python_cache 2>/dev/null || echo "python_cache volume exists"
        podman volume create cargo_registry 2>/dev/null || echo "cargo_registry volume exists"
        podman volume create postgres_data 2>/dev/null || echo "postgres_data volume exists"
        podman volume create redis_data 2>/dev/null || echo "redis_data volume exists"

        # Pull common development images
        echo "📦 Pulling common development images..."
        podman pull node:20-alpine &
        podman pull python:3.11-slim &
        podman pull rust:1.75-slim &
        podman pull postgres:15-alpine &
        podman pull redis:7-alpine &
        wait

        echo "✅ Container development environment setup complete!"
        echo ""
        echo "Next steps:"
        echo "  1. Initialize a project: container-dev init <template> <project-name>"
        echo "  2. Start development: container-dev start <environment>"
        echo "  3. Open VS Code with Remote-Containers extension"
      }

      init_project() {
        local template="$1"
        local project_name="''${2:-$(basename $(pwd))}"

        if [[ -z "$template" ]]; then
          echo "Error: Template name required"
          echo "Available templates: nodejs, python, rust, fullstack, microservices"
          exit 1
        fi

        echo "🏗️  Initializing $template project: $project_name"

        case "$template" in
          "nodejs")
            init_nodejs_project "$project_name"
            ;;
          "python")
            init_python_project "$project_name"
            ;;
          "rust")
            init_rust_project "$project_name"
            ;;
          "fullstack")
            init_fullstack_project "$project_name"
            ;;
          "microservices")
            init_microservices_project "$project_name"
            ;;
          *)
            echo "Error: Unknown template '$template'"
            exit 1
            ;;
        esac
      }

      init_nodejs_project() {
        local project_name="$1"

        # Create project structure
        mkdir -p "$project_name"/{src,public,tests,.devcontainer}
        cd "$project_name"

        # Package.json
        cat > package.json << EOF
      {
        "name": "$project_name",
        "version": "1.0.0",
        "description": "Node.js development project",
        "main": "src/index.js",
        "scripts": {
          "start": "node src/index.js",
          "dev": "nodemon src/index.js",
          "test": "jest",
          "build": "webpack --mode=production"
        },
        "devDependencies": {
          "nodemon": "^3.0.0",
          "jest": "^29.0.0"
        },
        "dependencies": {
          "express": "^4.18.0"
        }
      }
      EOF

        # Basic Express app
        cat > src/index.js << EOF
      const express = require('express');
      const app = express();
      const port = process.env.PORT || 3000;

      app.use(express.static('public'));

      app.get('/', (req, res) => {
        res.json({ message: 'Hello from containerized Node.js!' });
      });

      app.listen(port, '0.0.0.0', () => {
        console.log(\`Server running on port $${port}\`);
      });
      EOF

        # Dev container configuration
        cp "$CONFIG_DIR/../devcontainers/nodejs/.devcontainer.json" .devcontainer/

        # Podman compose for development
        cat > docker-compose.yml << EOF
      version: '3.8'
      services:
        app:
          build: .
          ports:
            - "3000:3000"
          volumes:
            - .:/workspace:cached
            - node_modules:/workspace/node_modules
          environment:
            - NODE_ENV=development
          networks:
            - development

      volumes:
        node_modules:

      networks:
        development:
          external: true
      EOF

        # Dockerfile
        cat > Dockerfile << EOF
      FROM node:20-alpine
      WORKDIR /workspace
      COPY package*.json ./
      RUN npm install
      COPY . .
      EXPOSE 3000
      CMD ["npm", "run", "dev"]
      EOF

        echo "✅ Node.js project '$project_name' initialized!"
        echo "📝 Next steps:"
        echo "   cd $project_name"
        echo "   container-dev start nodejs-dev"
        echo "   code . # Open in VS Code with Remote-Containers"
      }

      init_python_project() {
        local project_name="$1"

        mkdir -p "$project_name"/{src,tests,.devcontainer}
        cd "$project_name"

        # Requirements
        cat > requirements.txt << EOF
      fastapi==0.104.1
      uvicorn[standard]==0.24.0
      pydantic==2.5.0
      sqlalchemy==2.0.23
      pytest==7.4.3
      black==23.11.0
      flake8==6.1.0
      EOF

        # FastAPI app
        cat > src/main.py << EOF
      from fastapi import FastAPI
      from pydantic import BaseModel

      app = FastAPI(title="$project_name API")

      class Item(BaseModel):
          name: str
          description: str = None

      @app.get("/")
      async def root():
          return {"message": "Hello from containerized Python!"}

      @app.post("/items/")
      async def create_item(item: Item):
          return {"item": item}

      if __name__ == "__main__":
          import uvicorn
          uvicorn.run(app, host="0.0.0.0", port=8000)
      EOF

        # Dev container
        cp "$CONFIG_DIR/../devcontainers/python/.devcontainer.json" .devcontainer/

        # Docker compose
        cat > docker-compose.yml << EOF
      version: '3.8'
      services:
        app:
          build: .
          ports:
            - "8000:8000"
          volumes:
            - .:/workspace:cached
            - python_cache:/root/.cache/pip
          environment:
            - PYTHONPATH=/workspace/src
          networks:
            - development

      volumes:
        python_cache:

      networks:
        development:
          external: true
      EOF

        echo "✅ Python project '$project_name' initialized!"
      }

      start_environment() {
        local env_name="$1"

        if [[ -f "docker-compose.yml" ]]; then
          echo "🚀 Starting development environment..."
          podman-compose up -d
          echo "✅ Environment started!"
          echo "📊 Status:"
          podman-compose ps
        else
          echo "Error: No docker-compose.yml found in current directory"
          exit 1
        fi
      }

      show_status() {
        echo "=== Container Development Status ==="
        echo ""
        echo "🐳 Running Containers:"
        podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "🌐 Networks:"
        podman network ls
        echo ""
        echo "💾 Volumes:"
        podman volume ls
      }

      clean_environment() {
        echo "🧹 Cleaning up development environment..."

        # Stop all containers
        podman stop $(podman ps -q) 2>/dev/null || true

        # Remove stopped containers
        podman container prune -f

        # Remove unused volumes (keep named volumes)
        podman volume prune -f

        # Remove unused images
        podman image prune -f

        echo "✅ Cleanup complete!"
      }

      # Main command handling
      case "''${1:-}" in
        "setup")
          setup_environment
          ;;
        "init")
          shift
          init_project "$@"
          ;;
        "start")
          start_environment "''${2:-default}"
          ;;
        "status")
          show_status
          ;;
        "clean")
          clean_environment
          ;;
        "help"|"-h"|"--help")
          usage
          ;;
        *)
          echo "Error: Unknown command ''\${1:-}'"
          echo ""
          usage
          exit 1
          ;;
      esac
    '';
  };

  # Quick setup script for immediate use
  home.file.".local/bin/setup-containers" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "🚀 Quick Container Development Setup"
      echo "===================================="
      echo ""

      # Run the main setup
      container-dev setup

      echo ""
      echo "🎯 Quick Start Guide:"
      echo "1. Create a new project:"
      echo "   mkdir my-project && cd my-project"
      echo "   container-dev init nodejs my-project"
      echo ""
      echo "2. Start development:"
      echo "   container-dev start"
      echo ""
      echo "3. Open in VS Code:"
      echo "   code ."
      echo "   # Use 'Remote-Containers: Reopen in Container'"
      echo ""
      echo "4. Available commands:"
      echo "   container-dev help"
    '';
  };

  # Shell integration
  programs.zsh = {
    shellAliases = {
      # Quick container development
      "cdev" = "container-dev";
      "cdev-setup" = "setup-containers";
      "cdev-status" = "container-dev status";
      "cdev-clean" = "container-dev clean";

      # Project initialization shortcuts
      "init-node" = "container-dev init nodejs";
      "init-python" = "container-dev init python";
      "init-rust" = "container-dev init rust";
      "init-fullstack" = "container-dev init fullstack";
    };

    initContent = ''
      # Container development completion
      _container_dev_completion() {
        local commands="setup init start stop status clean network volume logs shell build deploy help"
        local templates="nodejs python rust fullstack microservices"

        if [[ $CURRENT -eq 2 ]]; then
          _describe 'commands' commands
        elif [[ $CURRENT -eq 3 && $words[2] == "init" ]]; then
          _describe 'templates' templates
        fi
      }

      compdef _container_dev_completion container-dev
      compdef _container_dev_completion cdev

      # Auto-detect project type and suggest container setup
      detect_container_project() {
        if [[ -f "docker-compose.yml" ]] || [[ -f "compose.yaml" ]]; then
          echo "🐳 Docker Compose detected - use 'podman-compose up'"
        elif [[ -f ".devcontainer/devcontainer.json" ]]; then
          echo "📦 Dev Container detected - open in VS Code Remote-Containers"
        elif [[ -f "package.json" ]]; then
          echo "📦 Node.js project - try 'init-node' to containerize"
        elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
          echo "🐍 Python project - try 'init-python' to containerize"
        elif [[ -f "Cargo.toml" ]]; then
          echo "🦀 Rust project - try 'init-rust' to containerize"
        fi
      }

      # Show container hints when entering directories
      chpwd_functions+=(detect_container_project)
    '';
  };

  # Session variables unified in containers-common.nix

  # Directory creation handled by containers-common.nix
}
