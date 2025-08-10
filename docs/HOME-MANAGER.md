This document provides detailed documentation for all Home Manager
features and configurations in the nix-config repository.

# Overview

Home Manager configurations are organized into feature modules that can
be composed per host. Each feature module encapsulates related
functionality and follows consistent patterns for configuration and
integration.

# Global Configuration

## Base Configuration ([`global/default.nix`](../home/dan/global/default.nix))

The global configuration provides the foundation for all Home Manager
setups.

### Core Settings

The global configuration sets foundational options such as the Home
Manager state version, enables Home Manager self-management, and
provides a base set of packages and secrets integration for all hosts.

### SOPS Integration

Secrets management is handled centrally and declaratively, making
secrets available to all feature modules through SOPS and age
encryption. == CLI Tools Features

## Git Configuration ([`features/cli/git.nix`](../home/dan/features/cli/git.nix))

Advanced Git configuration with conditional identity management and SOPS
integration.

### Identity Management

The Git configuration uses conditional includes to automatically switch
identities based on project directory:

``` nix
# Main .gitconfig with conditional includes
sops.templates."gitconfig" = {
  content = ''
    [user]
        name = ${config.sops.placeholder."git/personal/name"}
        email = ${config.sops.placeholder."git/personal/email"}

    [includeIf "gitdir:~/dev/${config.sops.placeholder."git/personal/folder"}/"]
        path = ~/.config/git/personal

    [includeIf "gitdir:~/dev/${config.sops.placeholder."git/company/folder"}/"]
        path = ~/.config/git/company

    [includeIf "gitdir:~/dev/${config.sops.placeholder."git/client001/folder"}/"]
        path = ~/.config/git/client001
  '';
};
```

The Git feature demonstrates advanced identity management and SOPS
integration, supporting multiple identities and secure credential
handling. === Shell Configuration
([`features/cli/zsh.nix`](../home/dan/features/cli/zsh.nix))

Comprehensive Zsh setup with Oh My Zsh, plugins, and custom
configurations.

### Core Features

The Zsh feature provides a modern shell environment with plugins,
completion, and usability enhancements. ==== Aliases and Shortcuts
Common aliases and shortcuts are provided for improved productivity and
safety.

### Advanced Configuration

## Terminal Configuration ([`features/cli/kitty.nix`](../home/dan/features/cli/kitty.nix))

Kitty terminal emulator, Starship prompt, SSH, Vim, and utility tools
are all configured as feature modules, following the same modular
pattern. See the respective module files for details. == macOS
Integration Features

macOS system preferences and platform integration are managed
declaratively through feature modules, ensuring consistent and
reproducible settings across machines. == Productivity Features

# Productivity Features

Productivity applications such as code editors, browsers, and general
tools are managed as feature modules. Their configuration is fully
declarative and reproducible, with details available in the respective
module files. == Feature Development Patterns

## Standard Module Structure

Each feature module follows a consistent structure:

``` nix
{ config, pkgs, lib, ... }: {
  # Package installation
  home.packages = with pkgs; [
    package-name
  ];

  # Program configuration
  programs.package-name = {
    enable = true;
    # program-specific options
  };

  # Optional: File management
  home.file.".config/app/config.yaml".text = ''
    # configuration content
  '';

  # Optional: Service configuration
  services.package-name = {
    enable = true;
    # service-specific options
  };

  # Optional: SOPS integration
  sops.secrets."app/secret" = {};

  # Optional: Environment variables
  home.sessionVariables = {
    APP_CONFIG = "value";
  };
}
```

## SOPS Integration Pattern

For features requiring secrets:

``` nix
{ config, pkgs, lib, ... }: {
  # Reference secrets defined in global configuration
  programs.app = {
    settings = {
      apiKey = config.sops.secrets."app/api-key".path;
    };
  };

  # Or use SOPS templates for complex configurations
  sops.templates."app-config" = {
    content = ''
      api_key: ${config.sops.placeholder."app/api-key"}
      username: ${config.sops.placeholder."app/username"}
    '';
    path = "${config.home.homeDirectory}/.config/app/config.yaml";
  };
}
```

## Cross-Feature Dependencies

When features depend on each other:

``` nix
{ config, pkgs, lib, ... }: {
  # Conditional configuration based on other features
  programs.app = lib.mkIf config.programs.other-app.enable {
    enable = true;
    integrations.other-app = true;
  };

  # Shared configuration patterns
  home.sessionVariables = lib.mkIf config.programs.shell.enable {
    APP_SHELL_INTEGRATION = "true";
  };
}
```

# Adding New Features

## Feature Module Creation

1.  **Create module file**:
    `home/dan/features/category/feature-name.nix`

2.  **Follow standard structure**: Use the established pattern

3.  **Document configuration**: Add inline comments for complex settings

4.  **Test integration**: Verify the feature works with existing setup

## Integration Steps

1.  **Import in host config**: Add to `home/dan/hostname.nix` imports

2.  **Handle dependencies**: Ensure required packages and services are
    available

3.  **Configure secrets**: Add any required secrets to SOPS
    configuration

4.  **Update documentation**: Document the feature in this file

## Best Practices

- **Modularity**: Keep features independent when possible

- **Configuration**: Use Home Manager options when available

- **Secrets**: Use SOPS for any sensitive information

- **Testing**: Test features individually and in combination

- **Documentation**: Document purpose, dependencies, and configuration
  options

This Home Manager configuration provides a solid foundation for user
environment management while maintaining flexibility for future
enhancements and additional features.
