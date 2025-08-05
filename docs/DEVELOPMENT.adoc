= Development Workflow and Guidelines
:toc: left
:toclevels: 3
:sectnums:
:icons: font

This document describes the development workflow, best practices, and guidelines for maintaining and extending the nix-config repository.

== Development Workflow

=== Daily Development Cycle

==== Making Changes

. **Edit configuration files**: Modify feature modules or host configurations
. **Test locally**: Apply changes with `darwin-rebuild build` (test without activation)
. **Apply changes**: Use `darwin-rebuild switch` or the `drs` alias
. **Verify functionality**: Test that new features work as expected
. **Commit changes**: Use conventional commit messages

==== Testing Strategy

[source,bash]
----
# Test configuration without applying
darwin-rebuild build --flake .#J6G6Y9JK7L

# Check what would be built/changed
darwin-rebuild build --flake .#J6G6Y9JK7L --dry-run

# Verbose output for debugging
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace

# Verify flake structure
nix flake check
----

==== Rollback Strategy

[source,bash]
----
# List available generations
darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild rollback

# Rollback to specific generation
sudo darwin-rebuild --switch-generation <number>
----

=== Feature Development

==== Creating New Features

. **Identify feature scope**: Determine what the feature should accomplish
. **Choose appropriate category**: CLI tools, macOS integration, or productivity
. **Create module file**: Follow the standard naming convention
. **Implement functionality**: Use Home Manager options when available
. **Test integration**: Verify compatibility with existing features
. **Document the feature**: Add to relevant documentation

==== Feature Module Template

Feature modules follow a standard pattern: they declare packages, configure programs, manage files, integrate secrets, set environment variables, and optionally define services. See existing modules for concrete examples.

==== Integration Patterns

===== SOPS Secrets Integration

SOPS secrets are defined globally and referenced in feature modules as needed, supporting both direct file references and template-based integration.

===== Cross-Feature Dependencies

Feature modules can conditionally integrate with each other using `lib.mkIf` and shared configuration patterns.

=== Host Configuration

==== Adding New Hosts

. **Create host directory**: `hosts/new-hostname/`
. **System configuration**: Create `hosts/new-hostname/default.nix`
. **Secrets file**: Create `hosts/new-hostname/secrets.yaml`
. **User configuration**: Create `home/dan/new-hostname.nix`
. **Update flake**: Add to `darwinConfigurations`

==== Host Configuration Guidelines

Host and user configuration files follow a modular pattern, importing global settings and selecting features as needed. See the codebase for up-to-date templates.

== Code Quality Guidelines

=== Nix Code Style

==== Formatting

* **Use nixpkgs-fmt**: Consistent formatting across all files
* **Indentation**: 2 spaces, no tabs
* **Line length**: Prefer 80-100 characters when practical
* **Attribute alignment**: Align equals signs in attribute sets

[source,bash]
----
# Format all Nix files
find . -name "*.nix" -exec nixpkgs-fmt {} \;

# Or use alejandra formatter
alejandra .
----

==== Code Organization

[source,nix]
----
# Good: Organized attribute set
{
  programs.git = {
    enable = true;
    userName = "user";
    userEmail = "user@example.com";
    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
    };
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "vim";
    };
  };
}

# Avoid: Unorganized mixing of options
{
  programs.git.enable = true;
  programs.git.extraConfig.init.defaultBranch = "main";
  programs.git.userName = "user";
  programs.git.aliases.co = "checkout";
  programs.git.userEmail = "user@example.com";
}
----

==== Comments and Documentation

[source,nix]
----
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
----

=== Module Design Principles

==== Single Responsibility

Each module should have one clear purpose:

* **Good**: `features/cli/git.nix` - Git configuration only
* **Avoid**: `features/cli/dev-tools.nix` - Mixed development tools

==== Minimal Coupling

Modules should be as independent as possible:

[source,nix]
----
# Good: Optional integration
programs.app-a = {
  enable = true;
  integration.app-b = lib.mkIf config.programs.app-b.enable true;
};

# Avoid: Hard dependency
programs.app-a = {
  enable = config.programs.app-b.enable;  # Forces app-b to be enabled
};
----

==== Configuration Over Code

Prefer declarative configuration:

[source,nix]
----
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
----

=== Secret Management

==== SOPS Best Practices

. **Centralize secret definitions**: Define all secrets in global configuration
. **Use descriptive names**: Clear hierarchy like `service/environment/key`
. **Template complex configs**: Use SOPS templates for multi-secret configurations
. **Document secret usage**: Comment on how secrets are used

[source,nix]
----
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
----

==== Secret Usage Patterns

[source,nix]
----
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
----

== Testing and Validation

=== Local Testing

==== Build Testing

[source,bash]
----
# Test without applying changes
darwin-rebuild build --flake .#J6G6Y9JK7L

# Check for common issues
nix flake check

# Validate specific configuration
nix build .#darwinConfigurations.J6G6Y9JK7L.system --dry-run
----

==== Configuration Validation

[source,bash]
----
# Test SOPS secrets access
sops -d hosts/J6G6Y9JK7L/secrets.yaml

# Validate Home Manager configuration
home-manager build --flake .

# Check for syntax errors
find . -name "*.nix" -exec nix-instantiate --parse {} \; > /dev/null
----

=== Debugging Techniques

==== Common Debug Commands

[source,bash]
----
# Verbose build output
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace

# Interactive debugging with nix repl
nix repl
:lf .
:p outputs.darwinConfigurations.J6G6Y9JK7L.config.programs.git

# Check package availability
nix search nixpkgs package-name
----

==== Troubleshooting Common Issues

===== Package Not Found

[source,bash]
----
# Search in different package sets
nix search nixpkgs package-name
nix search nixpkgs-unstable package-name

# Check package attributes
nix eval nixpkgs#package-name.pname
----

===== SOPS Issues

[source,bash]
----
# Verify age key exists and is readable
ls -la ~/Library/Application\ Support/sops/age/keys.txt

# Test secret decryption
sops -d hosts/J6G6Y9JK7L/secrets.yaml

# Check SOPS configuration
sops -d --extract '["key"]' hosts/J6G6Y9JK7L/secrets.yaml
----

===== Build Failures

[source,bash]
----
# Clean build cache
sudo nix-collect-garbage -d

# Update flake inputs
nix flake update

# Check for conflicting options
darwin-rebuild switch --flake .#J6G6Y9JK7L --show-trace 2>&1 | grep -i error
----

== Maintenance and Updates

=== Regular Maintenance Tasks

==== Weekly Tasks

[source,bash]
----
# Update flake inputs
nix flake update

# Apply updates
darwin-rebuild switch --flake .#J6G6Y9JK7L

# Clean old generations
sudo nix-collect-garbage --delete-older-than 7d
----

==== Monthly Tasks

[source,bash]
----
# Review and update pinned versions
nix flake update --commit-lock-file

# Review configuration for unused features
grep -r "enable = false" home/dan/features/

# Update documentation
# Review and update docs/ files
----

=== Version Management

==== Flake Input Updates

[source,bash]
----
# Update all inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Pin to specific commit
nix flake update nixpkgs --override-input nixpkgs github:NixOS/nixpkgs/commit-hash
----

==== Rollback Procedures

[source,bash]
----
# List available generations
darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild rollback

# Test rollback before committing
darwin-rebuild build --flake .#J6G6Y9JK7L --rollback
----

== Collaboration Guidelines

=== Git Workflow

==== Commit Message Format

Use conventional commit format:

[source,text]
----
feat(cli): add new shell utility configuration
fix(vscode): resolve extension compatibility issue
docs(readme): update installation instructions
refactor(modules): reorganize feature module structure
----

==== Branch Strategy

* **main**: Stable, working configurations
* **feature/**: New feature development
* **fix/**: Bug fixes and corrections
* **docs/**: Documentation updates

=== Code Review Checklist

When reviewing changes:

- [ ] Configuration follows established patterns
- [ ] No hardcoded paths or sensitive data
- [ ] Appropriate use of SOPS for secrets
- [ ] Documentation updated if needed
- [ ] Changes tested locally
- [ ] Commit messages follow convention

=== Documentation Maintenance

* **Keep docs current**: Update documentation with configuration changes
* **Include examples**: Provide usage examples for complex features
* **Link references**: Cross-reference related configurations
* **Explain decisions**: Document why specific choices were made

== Roadmap

include::TODO.adoc[]