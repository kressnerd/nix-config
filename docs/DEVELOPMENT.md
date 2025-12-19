This document describes the development workflow, best practices, and
guidelines for maintaining and extending the nix-config repository.

# Development Workflow

## Daily Development Cycle

### Making Changes

1.  **Edit configuration files**: Modify feature modules or host
    configurations

2.  **Test locally**: Apply changes with `darwin-rebuild build` (test
    without activation)

3.  **Apply changes**: Use `darwin-rebuild switch` or the `drs` alias

4.  **Verify functionality**: Test that new features work as expected

5.  **Commit changes**: Use conventional commit messages

### Testing Strategy

``` bash
# Test configuration without applying
darwin-rebuild build --flake .#J6G6Y9JK7L

# Check what would be built/changed
darwin-rebuild build --flake .#J6G6Y9JK7L --dry-run

# Verbose output for debugging
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace

# Verify flake structure
nix flake check
```

### Rollback Strategy

``` bash
# List available generations
darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild rollback

# Rollback to specific generation
sudo darwin-rebuild --switch-generation <number>
```

## Feature Development

### Creating New Features

1.  **Identify feature scope**: Determine what the feature should
    accomplish

2.  **Choose appropriate category**: CLI tools, macOS integration, or
    productivity

3.  **Create module file**: Follow the standard naming convention

4.  **Implement functionality**: Use Home Manager options when available

5.  **Test integration**: Verify compatibility with existing features

6.  **Document the feature**: Add to relevant documentation

### Feature Module Template

Feature modules follow a standard pattern: they declare packages,
configure programs, manage files, integrate secrets, set environment
variables, and optionally define services. See existing modules for
concrete examples.

### Integration Patterns

#### SOPS Secrets Integration

SOPS secrets are defined globally and referenced in feature modules as
needed, supporting both direct file references and template-based
integration.

#### Cross-Feature Dependencies

Feature modules can conditionally integrate with each other using
`lib.mkIf` and shared configuration patterns.

## Host Configuration

### Adding New Hosts

1.  **Create host directory**: `hosts/new-hostname/`

2.  **System configuration**: Create `hosts/new-hostname/default.nix`

3.  **Secrets file**: Create `hosts/new-hostname/secrets.yaml`

4.  **User configuration**: Create `home/dan/new-hostname.nix`

5.  **Update flake**: Add to `darwinConfigurations`

### Host Configuration Guidelines

Host and user configuration files follow a modular pattern, importing
global settings and selecting features as needed. See the codebase for
up-to-date templates.

# Code Quality Guidelines

## Nix Code Style

### Formatting

- **Use nixpkgs-fmt**: Consistent formatting across all files

- **Indentation**: 2 spaces, no tabs

- **Line length**: Prefer 80-100 characters when practical

- **Attribute alignment**: Align equals signs in attribute sets

``` bash
# Format all Nix files
find . -name "*.nix" -exec nixpkgs-fmt {} \;

# Or use alejandra formatter
alejandra .
```

### Code Organization

``` nix
# Good: Organized attribute set
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "user";
      email = "user@example.com";
    };
    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
    };
    settings = {
      init.defaultBranch = "main";
      core.editor = "vim";
    };
  };
}

# Avoid: Unorganized mixing of options
{
  programs.git.enable = true;
  programs.git.extraConfig.init.defaultBranch = "main";
  programs.git.settings.user.name = "user";
  programs.git.aliases.co = "checkout";
  programs.git.settings.user.email = "user@example.com";
}
```

### Comments and Documentation

``` nix
{
  # Feature description and purpose
  programs.feature = {
    enable = true;
    # Explanation of complex configuration
    settings = {
      # Why this specific value is chosen
      complexOption = "specific-value";
    };
  };

  # SOPS integration for sensitive data
  sops.templates."config-file" = {
    content = ''
      # Template explanation
      api_key: ${config.sops.placeholder."app/api-key"}
    '';
    path = "${config.home.homeDirectory}/.config/app/config.yaml";
  };
}
```

## Module Design Principles

### Single Responsibility

Each module should have one clear purpose:

- **Good**: `features/cli/git.nix` - Git configuration only

- **Avoid**: `features/cli/dev-tools.nix` - Mixed development tools

### Minimal Coupling

Modules should be as independent as possible:

``` nix
# Good: Optional integration
programs.app-a = {
  enable = true;
  integration.app-b = lib.mkIf config.programs.app-b.enable true;
};

# Avoid: Hard dependency
programs.app-a = {
  enable = config.programs.app-b.enable;  # Forces app-b to be enabled
};
```

### Configuration Over Code

Prefer declarative configuration:

``` nix
# Good: Declarative configuration
programs.zsh = {
  enable = true;
  shellAliases = {
    ll = "ls -la";
    la = "ls -A";
  };
  initContent = ''
    setopt AUTO_CD
  '';
};

# Avoid: Complex scripting
home.file.".zshrc".text = ''
  # Complex shell script that could be declarative
  if command -v ls >/dev/null; then
    alias ll='ls -la'
  fi
'';
```

## Secret Management

### SOPS Best Practices

1.  **Centralize secret definitions**: Define all secrets in global
    configuration

2.  **Use descriptive names**: Clear hierarchy like
    `service/environment/key`

3.  **Template complex configs**: Use SOPS templates for multi-secret
    configurations

4.  **Document secret usage**: Comment on how secrets are used

``` nix
# Good: Well-organized secret schema
sops.secrets = {
  # Git identity management
  "git/personal/name" = {};
  "git/personal/email" = {};
  "git/company/name" = {};
  "git/company/email" = {};
  # Development services
  "services/github/token" = {};
  "services/npm/token" = {};
  # Infrastructure
  "infrastructure/aws/access-key" = {};
  "infrastructure/aws/secret-key" = {};
};
```

### Secret Usage Patterns

``` nix
# Pattern 1: Direct file reference
programs.gh = {
  settings = {
    git_protocol = "ssh";
    oauth_token = config.sops.secrets."services/github/token".path;
  };
};

# Pattern 2: SOPS templates for complex configs
sops.templates."aws-credentials" = {
  content = ''
    [default]
    aws_access_key_id = ${config.sops.placeholder."infrastructure/aws/access-key"}
    aws_secret_access_key = ${config.sops.placeholder."infrastructure/aws/secret-key"}
  '';
  path = "${config.home.homeDirectory}/.aws/credentials";
  mode = "0600";
};
```

# Testing and Validation

## Local Testing

### Build Testing

``` bash
# Test without applying changes
darwin-rebuild build --flake .#J6G6Y9JK7L

# Check for common issues
nix flake check

# Validate specific configuration
nix build .#darwinConfigurations.J6G6Y9JK7L.system --dry-run
```

### Configuration Validation

``` bash
# Test SOPS secrets access
sops -d hosts/J6G6Y9JK7L/secrets.yaml

# Validate Home Manager configuration
home-manager build --flake .

# Check for syntax errors
find . -name "*.nix" -exec nix-instantiate --parse {} \; > /dev/null
```

## Debugging Techniques

### Common Debug Commands

``` bash
# Verbose build output
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace

# Interactive debugging with nix repl
nix repl
:lf .
:p outputs.darwinConfigurations.J6G6Y9JK7L.config.programs.git

# Check package availability
nix search nixpkgs package-name
```

### Troubleshooting Common Issues

#### Package Not Found

``` bash
# Search in different package sets
nix search nixpkgs package-name
nix search nixpkgs-unstable package-name

# Check package attributes
nix eval nixpkgs#package-name.pname
```

#### SOPS Issues

``` bash
# Verify age key exists and is readable
ls -la ~/Library/Application\ Support/sops/age/keys.txt

# Test secret decryption
sops -d hosts/J6G6Y9JK7L/secrets.yaml

# Check SOPS configuration
sops -d --extract '["key"]' hosts/J6G6Y9JK7L/secrets.yaml
```

#### Build Failures

``` bash
# Clean build cache
sudo nix-collect-garbage -d

# Update flake inputs
nix flake update

# Check for conflicting options
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace 2>&1 | grep -i error
```

# Maintenance and Updates

## Regular Maintenance Tasks

### Weekly Tasks

``` bash
# Update flake inputs
nix flake update

# Apply updates
darwin-rebuild switch --flake .#J6G6Y9JK7L

# Clean old generations
sudo nix-collect-garbage --delete-older-than 7d
```

### Monthly Tasks

``` bash
# Review and update pinned versions
nix flake update --commit-lock-file

# Review configuration for unused features
grep -r "enable = false" home/dan/features/

# Update documentation
# Review and update docs/ files
```

## Version Management

### Flake Input Updates

``` bash
# Update all inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Pin to specific commit
nix flake update nixpkgs --override-input nixpkgs github:NixOS/nixpkgs/commit-hash
```

### Rollback Procedures

``` bash
# List available generations
darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild rollback

# Test rollback before committing
darwin-rebuild build --flake .#J6G6Y9JK7L --rollback
```

# Collaboration Guidelines

## Git Workflow

### Commit Message Format

Use conventional commit format:

``` text
feat(cli): add new shell utility configuration
fix(vscode): resolve extension compatibility issue
docs(readme): update installation instructions
refactor(modules): reorganize feature module structure
```

### Branch Strategy

- **main**: Stable, working configurations

- **feature/**: New feature development

- **fix/**: Bug fixes and corrections

- **docs/**: Documentation updates

## Code Review Checklist

When reviewing changes:

- \[ \] Configuration follows established patterns

- \[ \] No hardcoded paths or sensitive data

- \[ \] Appropriate use of SOPS for secrets

- \[ \] Documentation updated if needed

- \[ \] Changes tested locally

- \[ \] Commit messages follow convention

## Documentation Maintenance

- **Keep docs current**: Update documentation with configuration changes

- **Include examples**: Provide usage examples for complex features

- **Link references**: Cross-reference related configurations

- **Explain decisions**: Document why specific choices were made

# Roadmap

# Nix Configuration Improvement Todo List

Based on the comprehensive configuration review, here’s a prioritized
action plan for enhancing the nix-darwin setup.

## 🚨 High Priority - Fix Anti-patterns

### Remove imperative package management aliases

- \[ \] **Remove imperative package management aliases** from
  [`zsh.nix`](../home/dan/features/cli/zsh.nix)

  - Remove or comment out `ne = "nix-env"` alias (line 54)

  - Add warning comment about avoiding `nix-env -i` for permanent
    installations

  - Update documentation to emphasize declarative alternatives

- \[ \] **Add declarative alternatives documentation**

  - Create examples showing how to add packages via `home.packages`
    instead of `nix-env`

  - Document how to use `nix shell` for temporary tool access

  - Add section on why imperative package management breaks
    reproducibility

## 🔧 Short-term Enhancements (1-2 weeks)

## Security Improvements

- \[ \] **Implement GPG signing for Git commits**

  - Add GPG key management to SOPS secrets

  - Configure conditional GPG signing per identity

  - Document key generation and management procedures

- \[ \] **Document SOPS key backup procedures**

  - Create backup strategy for age keys

  - Document key rotation procedures

  - Add recovery instructions for lost keys

## Configuration Enhancements

- \[ \] **Create package overlays for customizations**

  - Add `overlays/` directory structure

  - Create example overlay for package modifications

  - Document overlay usage patterns

- \[ \] **Add user-level service management**

  - Identify candidates for Home Manager services

  - Implement background services (e.g., backup scripts, sync tools)

  - Document service management patterns

### Development Workflow

- \[ \] **Add configuration validation scripts**

  - Create pre-commit hooks for `nix flake check`

  - Add CI/CD pipeline for testing configurations

  - Document testing procedures for new features

## 📊 Medium-term Goals (1-2 months)

### Multi-host Support

- \[ \] **Prepare for additional macOS machines**

  - Abstract host-specific configurations

  - Create shared module library

  - Document host addition procedures

- \[ \] **Create reusable module templates**

  - Standardize feature module patterns

  - Create scaffolding for new features

  - Document module development guidelines

### Enhanced Functionality

- \[ \] **Implement custom derivations**

  - Identify packages that need customization

  - Create `pkgs/` directory for custom packages

  - Document package creation workflow

- \[ \] **Add development environment automation**

  - Create project-specific `shell.nix` templates

  - Implement `direnv` integration for automatic environments

  - Document development workflow patterns

### Documentation Expansion

- \[ \] **Create troubleshooting guides**

  - Common build failures and solutions

  - SOPS troubleshooting procedures

  - Performance optimization tips

- \[ \] **Add migration guides**

  - From imperative to declarative package management

  - Upgrading between NixOS versions

  - Adding new features safely

## 🚀 Long-term Vision (3-6 months)

### Cross-platform Preparation

- \[ \] **Structure for Linux compatibility**

  - Abstract platform-specific configurations

  - Create shared cross-platform modules

  - Plan NixOS integration strategy

- \[ \] **Infrastructure as Code integration**

  - Evaluate cloud resource management needs

  - Plan integration with deployment tools

  - Document infrastructure patterns

### Advanced Features

- \[ \] **Custom NixOS modules development**

  - Identify reusable system patterns

  - Create custom options and modules

  - Contribute back to community

- \[ \] **Automated backup and sync**

  - Implement configuration backup automation

  - Create sync strategies for multiple machines

  - Document disaster recovery procedures

## 📝 Documentation Tasks

### Immediate Updates

- \[ \] **Update README with anti-pattern warnings**

  - Add section on avoiding imperative package management

  - Include troubleshooting for common mistakes

  - Document best practices clearly

- \[ \] **Create feature addition workflow guide**

  - Step-by-step module creation process

  - Testing and validation procedures

  - Integration best practices

### Content Expansion

- \[ \] **Add real-world usage examples**

  - Common development scenarios

  - Multi-project identity management

  - Tool integration patterns

- \[ \] **Create video or interactive tutorials**

  - Configuration walkthrough

  - Feature demonstration

  - Troubleshooting sessions

## 🔍 Monitoring and Maintenance

### Regular Tasks

- \[ \] **Set up automated dependency updates**

  - Weekly `flake.lock` update checks

  - Automated testing of updates

  - Rollback procedures for failures

- \[ \] **Performance monitoring**

  - Build time tracking

  - Configuration size monitoring

  - System resource usage analysis

### Quality Assurance

- \[ \] **Implement configuration testing**

  - Automated build verification

  - Feature functionality testing

  - Documentation accuracy checks

- \[ \] **Code review processes**

  - Peer review for significant changes

  - Security review for secrets handling

  - Performance impact assessment

## 📅 Priority Ranking

| Timeframe | Focus Areas |
|----|----|
| **Week 1** | Fix anti-patterns, add GPG signing, create overlays structure |
| **Week 2** | Implement user services, add validation scripts, update documentation |
| **Month 1** | Multi-host preparation, custom derivations, troubleshooting guides |
| **Month 2-3** | Cross-platform preparation, advanced features, automation |
| **Ongoing** | Regular maintenance, monitoring, quality assurance |
