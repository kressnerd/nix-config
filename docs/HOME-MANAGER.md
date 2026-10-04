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
encryption.

# CLI Tools Features

## Git Configuration ([`features/cli/git.nix`](../home/dan/features/cli/git.nix))

Advanced Git configuration with conditional identity management, SOPS
integration, and SSH key isolation.

### Identity Management & SSH Key Isolation

The Git configuration uses conditional includes (`includeIf`) based on project directory
paths to switch identities (e.g. personal, company, client projects) automatically:

```nix
# Main ~/.gitconfig with conditional includes (SOPS template)
[user]
    name = ${config.sops.placeholder."git/personal/name"}
    email = ${config.sops.placeholder."git/personal/email"}

[includeIf "gitdir:~/dev/${config.sops.placeholder."git/personal/folder"}/"]
    path = ~/.config/git/personal

[includeIf "gitdir:~/dev/${config.sops.placeholder."git/company/folder"}/"]
    path = ~/.config/git/company

[includeIf "gitdir:~/dev/${config.sops.placeholder."git/client001/folder"}/"]
    path = ~/.config/git/client001
```

Each identity profile template (`~/.config/git/<identity>`) combines two mechanisms to
guarantee that the correct identity and SSH key are strictly isolated:

1. **Explicit Key Isolation (`core.sshCommand`):**
   ```gitconfig
   [core]
       sshCommand = "ssh -i ~/.ssh/id_ed25519_personal_2026-10-04 -o IdentitiesOnly=yes"
   ```
   Setting `sshCommand` with `-o IdentitiesOnly=yes` guarantees that SSH uses only the
   explicitly configured identity file for operations inside that directory tree, preventing
   the SSH agent from offering arbitrary other keys.

2. **Transparent URL Rewriting (`url.<base>.insteadOf`):**
   ```gitconfig
   [url "git@github-personal:"]
       insteadOf = git@github.com:
   ```
   Standard clone URLs (such as `git@github.com:org/repo.git`) are rewritten at runtime to
   custom SSH host aliases (`github-personal`, `github-company`, `github-client001`,
   `bitbucket-client002`), which map directly to host entries in `~/.ssh/config`.

---

## SSH Configuration ([`features/cli/ssh.nix`](../home/dan/features/cli/ssh.nix))

Manages SSH client configuration, host aliases, agent lifecycle, and OS keychain integration.

### Host Aliases

SSH host blocks correspond to the identities rewritten by Git:

```nix
programs.ssh.settings = {
  "github-personal" = {
    HostName = "github.com";
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519_personal_2026-10-04";
    IdentitiesOnly = true;
  };

  "github-company" = {
    HostName = "github.com";
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519_company_2025-06-18";
    IdentitiesOnly = true;
  };

  "github-client001" = {
    HostName = "github.com";
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519_client001_2025-07-22";
    IdentitiesOnly = true;
  };

  "bitbucket-client002" = {
    HostName = "bitbucket.org";
    User = "git";
    IdentityFile = "~/.ssh/id_ed25519_client002_2026-01-13";
    IdentitiesOnly = true;
  };
};
```

### SSH Agent Architecture & macOS Keychain vs. GPG Agent

Authentication agents are configured per platform:

- **Linux (NixOS):** `services.ssh-agent.enable = true` manages the SSH agent as a systemd user service.
- **macOS (Darwin):** The agent is managed natively by macOS `launchd`. Home Manager configures:
  ```nix
  programs.ssh.settings."*" = {
    AddKeysToAgent = "yes";
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    IgnoreUnknown = "UseKeychain";
    UseKeychain = "yes";
    IdentitiesOnly = true;
  };
  ```

#### macOS Keychain vs. GPG Agent Conflict

On macOS, `services.gpg-agent.enableSshSupport` **must remain disabled** (`false`):

- **Problem:** If `services.gpg-agent.enableSshSupport = true;` is set, shell initialization points
  `SSH_AUTH_SOCK` to `~/.gnupg/S.gpg-agent.ssh`. The GPG agent does not support Apple's Keychain protocol
  flags (`--apple-use-keychain`), causing `/usr/bin/ssh-add --apple-use-keychain` to fail with
  `agent refused operation`.
- **Resolution:** Disabling `enableSshSupport` keeps `SSH_AUTH_SOCK` connected to the native macOS `launchd`
  agent, allowing seamless key storage and retrieval via Apple Keychain.
- **Commit signing:** GPG Agent remains active purely for GPG signing operations (e.g. Magit in Doom Emacs)
  using `pinentry_mac`, without hijacking SSH authentication.

---

## Shell Configuration ([`features/cli/zsh.nix`](../home/dan/features/cli/zsh.nix), [`features/cli/fish.nix`](../home/dan/features/cli/fish.nix))

Comprehensive shell setups providing modern environments with plugins, completions, and custom configurations.

### Core Features

- Modern interactive prompt integration (Starship).
- Shared and shell-specific aliases for common operations (`ll`, `gs`, `icat`, etc.).
- Vi key bindings and custom helper functions.

---

## Terminal Configuration ([`features/cli/kitty.nix`](../home/dan/features/cli/kitty.nix))

Kitty terminal emulator, Starship prompt, Vim, and utility tools are configured as composable feature modules following the same modular pattern.

# macOS Integration Features

macOS system preferences and platform integration are managed declaratively through feature modules (such as `features/macos/aerospace.nix` and `features/macos/defaults.nix`), ensuring consistent settings across darwin hosts.

# Productivity Features

Productivity applications such as code editors (Doom Emacs, VS Code), browsers (Firefox personal/company profiles), and general tools are managed as feature modules. Their configuration is fully declarative and reproducible.

# Feature Development Patterns

## Standard Module Structure

Each feature module follows a consistent structure:

```nix
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

```nix
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

```nix
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
