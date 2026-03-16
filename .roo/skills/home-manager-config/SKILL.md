# Skill: Home Manager Configuration

**Applies to**: architect, code, nix-expert
**Trigger**: Configuring user programs, shells, editors, browsers, desktop environments, or cross-platform features

## Scope

Deep expertise in Home Manager user-level configuration: program modules, shell setup, editor configuration, XDG management, and cross-platform patterns (Linux/macOS). Extends the basic patterns in `.roo/rules/12-nix-patterns.md`.

## Prerequisites (from existing rules)

- Repository layout: `.roo/rules/11-repository-conventions.md`
- Feature composition: `.roo/rules/12-nix-patterns.md` (Feature Toggle Pattern)
- Editing safety: `.roo/rules-code/02-editing-safety.md`

---

## 1. Feature Module Pattern (this repo)

### File Location

```
home/dan/features/<category>/<name>.nix
```

Categories: `cli/`, `development/`, `productivity/`, `linux/`, `macos/`

### Standard Feature Template

```nix
{ pkgs, ... }:
{
  # Package installation
  home.packages = with pkgs; [
    tool-name
  ];

  # Program configuration (preferred over home.packages when available)
  programs.tool-name = {
    enable = true;
    # program-specific options
  };
}
```

### Wiring a Feature into a Host Profile

```nix
# home/dan/<hostname>.nix
{ ... }:
{
  imports = [
    ./global/default.nix
    ./features/cli/git.nix
    ./features/cli/zsh.nix
    ./features/productivity/vscode.nix
    # New feature:
    ./features/cli/tmux.nix
  ];

  home.username = "dan";
  home.homeDirectory = "/home/dan";  # or /Users/dan on macOS
}
```

---

## 2. Shell Configuration

### Zsh

```nix
programs.zsh = {
  enable = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;
  
  shellAliases = {
    ll = "ls -la";
    rebuild = "sudo nixos-rebuild switch --flake .#hostname";
  };

  initExtra = ''
    # Extra shell init commands
  '';

  oh-my-zsh = {
    enable = true;
    plugins = [ "git" "docker" "kubectl" ];
    theme = "robbyrussell";
  };
};
```

### Fish

```nix
programs.fish = {
  enable = true;
  shellAliases = { ... };
  interactiveShellInit = ''
    # Fish-specific init
  '';
  plugins = [
    { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; }
  ];
};
```

### Starship (cross-shell prompt)

```nix
programs.starship = {
  enable = true;
  settings = {
    add_newline = false;
    character.success_symbol = "[➜](bold green)";
    nix_shell.disabled = false;
  };
};
```

---

## 3. Editor Configuration

### Vim/Neovim

```nix
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  plugins = with pkgs.vimPlugins; [
    telescope-nvim
    nvim-treesitter.withAllGrammars
    nvim-lspconfig
  ];
  extraLuaConfig = ''
    -- Lua configuration here
  '';
};
```

### VS Code

```nix
programs.vscode = {
  enable = true;
  extensions = with pkgs.vscode-extensions; [
    jnoortheen.nix-ide
    ms-python.python
    # Custom extensions via overlay
    pkgs.roo-cline  # From overlays/vscode-extensions/
  ];
  userSettings = {
    "editor.fontSize" = 14;
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
  };
};
```

### Emacs

```nix
programs.emacs = {
  enable = true;
  package = pkgs.emacs29;
  extraPackages = epkgs: with epkgs; [
    magit
    nix-mode
    org
  ];
};
```

---

## 4. Git Configuration

```nix
programs.git = {
  enable = true;
  userName = "Daniel Kressner";
  userEmail = "email@example.com";
  
  signing = {
    key = "KEYID";
    signByDefault = true;
  };

  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    core.autocrlf = "input";
  };

  aliases = {
    co = "checkout";
    br = "branch";
    st = "status";
    lg = "log --oneline --graph --decorate";
  };

  delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  ignores = [ ".direnv" ".envrc" "result" ];
};
```

---

## 5. Terminal Emulators

### Kitty

```nix
programs.kitty = {
  enable = true;
  font = {
    name = "JetBrains Mono";
    size = 12;
  };
  settings = {
    scrollback_lines = 10000;
    enable_audio_bell = false;
    tab_bar_style = "powerline";
    background_opacity = "0.95";
  };
  theme = "Catppuccin-Mocha";
};
```

### Alacritty

```nix
programs.alacritty = {
  enable = true;
  settings = {
    font = {
      normal.family = "JetBrains Mono";
      size = 12.0;
    };
    window.opacity = 0.95;
  };
};
```

---

## 6. Browser Configuration

### Firefox (with extensions)

```nix
programs.firefox = {
  enable = true;
  profiles.default = {
    id = 0;
    isDefault = true;
    settings = {
      "browser.startup.homepage" = "https://search.example.com";
      "privacy.trackingprotection.enabled" = true;
    };
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      bitwarden
      privacy-badger
    ];
    search = {
      default = "DuckDuckGo";
      force = true;
    };
  };
};
```

---

## 7. XDG Configuration

```nix
xdg = {
  enable = true;
  userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
  };
  
  # Arbitrary config files
  configFile."app/config.toml".text = ''
    [section]
    key = "value"
  '';
  
  configFile."app/config.toml".source = ./config/app.toml;
};
```

---

## 8. File Management

```nix
# Place files in home directory
home.file = {
  ".config/app/settings.json".text = builtins.toJSON {
    setting = "value";
  };
  
  ".local/bin/script.sh" = {
    source = ./scripts/my-script.sh;
    executable = true;
  };
  
  # Symlink entire directory
  ".config/doom" = {
    source = ./doom.d;
    recursive = true;
  };
};
```

---

## 9. Cross-Platform Patterns

### Platform-Conditional Packages

```nix
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    # Cross-platform
    ripgrep
    fd
    bat
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # Linux-only
    xclip
    wl-clipboard
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # macOS-only
    darwin.apple_sdk.frameworks.Security
  ];
}
```

### Platform-Specific Features (this repo)

- Linux-only features: `home/dan/features/linux/` (Hyprland, fonts, impermanence)
- macOS-only features: `home/dan/features/macos/` (system defaults)
- Cross-platform features: all other directories

### macOS System Defaults

```nix
# home/dan/features/macos/defaults.nix
{ ... }:
{
  targets.darwin.defaults = {
    "com.apple.dock" = {
      autohide = true;
      minimize-to-application = true;
      tilesize = 48;
    };
    "com.apple.finder" = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
  };
}
```

---

## 10. Session Variables and Services

### Environment Variables

```nix
home.sessionVariables = {
  EDITOR = "nvim";
  VISUAL = "code";
  PAGER = "less -R";
  LANG = "en_US.UTF-8";
};

home.sessionPath = [
  "$HOME/.local/bin"
  "$HOME/go/bin"
];
```

### User Services (systemd user units, Linux only)

```nix
systemd.user.services.my-service = {
  Unit.Description = "My background service";
  Service = {
    ExecStart = "${pkgs.my-tool}/bin/my-tool --daemon";
    Restart = "on-failure";
  };
  Install.WantedBy = [ "default.target" ];
};
```

---

## 11. MCP Integration

Use MCP for Home Manager option discovery:
- `home_manager_search` — Find available HM options
- `darwin_search` — Find nix-darwin/HM macOS options

### Example Query Pattern

Before configuring a program, check if HM has a module:
1. Search: `home_manager_search("programs.<name>")` 
2. If module exists → use `programs.<name>.enable = true;`
3. If not → fall back to `home.packages` + `home.file` / `xdg.configFile`
