# Comprehensive Containerized Development Environment Setup

This guide provides a complete containerized development environment for macOS using Nix Darwin and Home Manager with Podman as the core container runtime.

## Overview

Your new container development setup includes:

- **Podman**: Rootless, daemonless container runtime (Docker compatible)
- **VS Code Integration**: Dev containers with pre-configured templates
- **Nix Container Building**: Build container images declaratively with Nix
- **Advanced Networking**: Custom networks and volume mounting strategies
- **Development Workflows**: Automated project setup and management

## Quick Start

### 1. Enable Container Features

Add to your [`home/dan/J6G6Y9JK7L.nix`](home/dan/J6G6Y9JK7L.nix):

```nix
{
  imports = [
    # ... existing imports ...
    ./features/development/containers.nix
  ];
}
```

### 2. Rebuild Your Configuration

```bash
# Rebuild home-manager configuration
home-manager switch --flake .#J6G6Y9JK7L

# Or if using darwin-rebuild
darwin-rebuild switch --flake .
```

### 3. Initial Setup

```bash
# Run initial container environment setup
setup-containers

# Or manually
container-dev setup
```

## Container Runtime Options Explained

### 1. **Podman** (Recommended)

- ✅ **Rootless**: More secure, no daemon required
- ✅ **Docker Compatible**: Works with `docker-compose` files
- ✅ **Pod Support**: Native pod management (like Kubernetes)
- ✅ **Nix Integration**: Fully declarative configuration

### 2. **Lima** (For Full Linux VMs)

- ✅ **Full Linux Environment**: When containers aren't enough
- ❌ **Resource Heavy**: Uses more CPU/memory than containers
- ❌ **Complexity**: Additional VM management overhead

### 3. **OrbStack** (Commercial)

- ❌ **Proprietary**: Not declaratively manageable
- ❌ **Commercial**: Subscription-based for teams
- ❌ **Non-Nix**: Doesn't align with declarative approach

### 4. **Docker Desktop**

- ❌ **Resource Heavy**: Known performance issues on macOS
- ❌ **Commercial**: License restrictions for larger teams
- ❌ **Less Secure**: Requires root daemon

## Development Workflows

### Create New Projects

```bash
# Node.js project
mkdir my-node-app && cd my-node-app
container-dev init nodejs my-node-app

# Python project
mkdir my-python-app && cd my-python-app
container-dev init python my-python-app

# Full-stack project
mkdir my-fullstack-app && cd my-fullstack-app
container-dev init fullstack my-fullstack-app
```

### Start Development Environment

```bash
# Start containers
container-dev start

# Check status
container-dev status

# View logs
podman-compose logs -f
```

### VS Code Integration

1. **Install Extensions** (if not already installed):

   - Remote - Containers
   - Docker (works with Podman)

2. **Open Project in Container**:

   ```bash
   code .
   # Command Palette: "Dev Containers: Reopen in Container"
   ```

3. **Manual Dev Container Setup**:
   ```bash
   # Create dev container configuration
   devcontainer-create nodejs-dev nodejs .
   ```

### Nix Container Building

```bash
# Build container with Nix (if flake.nix exists)
nix build .#container

# Load into Podman
podman load < result

# Run built container
podman run --rm -it my-app:latest
```

## Networking and Volumes

### Development Networks

Your setup includes pre-configured networks:

- **`development`**: Default development network (10.89.0.0/16)
- **`isolated`**: Internal-only network (10.90.0.0/16)

```bash
# List networks
podman network ls

# Inspect network
podman network inspect development
```

### Volume Strategies

Choose the right volume strategy for your needs:

```bash
# Live source code (fastest updates)
-v "$(pwd):/workspace:rw"

# Cached volumes (better macOS performance)
-v "$(pwd):/workspace:rw,cached"

# Delegated volumes (best write performance)
-v "$(pwd):/workspace:rw,delegated"

# Named volumes (persistent data)
-v "node_modules:/workspace/node_modules"
```

### Test Volume Performance

```bash
# Test different mount types
test-volume-performance bind
test-volume-performance cached
test-volume-performance delegated
test-volume-performance volume
```

## Advanced Features

### Container Orchestration

```bash
# Multi-service development environment
podman-compose -f .config/containers/examples/networking-compose.yaml up -d

# Scale services
podman-compose up -d --scale backend=3

# View service logs
podman-compose logs -f backend
```

### Kubernetes Development

```bash
# Start local Kubernetes (if using Lima)
k8s-dev

# Deploy application
kubectl apply -f .config/containers/examples/k8s-deployment.yaml

# Monitor with k9s
k9s
```

### Container Security

```bash
# Scan image for vulnerabilities
grype my-app:latest

# Generate SBOM
syft my-app:latest

# Sign container image
cosign sign my-app:latest
```

## Troubleshooting

### Common Issues

1. **Podman Socket Issues**:

   ```bash
   # Check Podman status
   podman system info

   # Restart Podman if needed
   podman system reset
   ```

2. **Volume Mount Performance**:

   - Use `cached` or `delegated` options on macOS
   - Use named volumes for `node_modules`, etc.

3. **Network Connectivity**:

   ```bash
   # Debug container network
   debug-container-network <container-name>

   # Test network connectivity
   podman run --rm nicolaka/netshoot
   ```

4. **VS Code Dev Containers**:
   - Ensure Docker path points to Podman: `/opt/homebrew/bin/podman`
   - Check dev container configuration in `.devcontainer/devcontainer.json`

### Performance Optimization

```bash
# Clean up unused resources
container-cleanup

# Remove all containers and volumes (nuclear option)
container-dev clean

# Optimize Podman storage
podman system prune -af
```

## Available Commands

### Quick Commands

- `cdev` - Alias for `container-dev`
- `cdev-setup` - Run initial setup
- `cdev-status` - Show container status
- `init-node` - Initialize Node.js project
- `init-python` - Initialize Python project

### Development Commands

- `dev-env start nodejs-dev` - Start Node.js environment
- `podman-compose up -d` - Start compose services
- `dive <image>` - Explore container layers
- `lazydocker` - Container management TUI

### Podman Aliases

- `p` = `podman`
- `pc` = `podman-compose`
- `pps` = `podman ps`
- `pi` = `podman images`

## File Structure

Your container configuration is organized as:

```
~/.config/containers/
├── environments/          # Compose file templates
├── networks/             # Network configurations
├── volumes/              # Volume mount strategies
├── examples/             # Example configurations
└── templates/            # Project templates

~/.config/devcontainers/
├── nodejs/               # Node.js dev container
├── python/               # Python dev container
└── rust/                # Rust dev container
```

## Next Steps

1. **Try the Quick Start**: Run `setup-containers` and create your first project
2. **Explore Templates**: Check available project templates with `container-dev init`
3. **Customize Networks**: Modify network configurations in `.config/containers/networks/`
4. **Build with Nix**: Create Nix flakes for reproducible container builds
5. **Integrate CI/CD**: Use the same container definitions in your deployment pipelines

## Support

- **Podman Documentation**: https://podman.io/docs
- **VS Code Dev Containers**: https://code.visualstudio.com/docs/devcontainers/containers
- **Nix Container Building**: https://github.com/nlewo/nix2container

---

**🎉 Your containerized development environment is ready!**

Start with: `setup-containers` and then `container-dev init nodejs my-first-project`
