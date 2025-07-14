{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    # Enable useful features
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Common aliases
    shellAliases = {
      # Listing
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";

      # Git shortcuts
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";

      # Editor shortcuts
      v = "vim";
      vi = "vim";

      # Kitty specific
      icat = "kitty +kitten icat";
      ssh = "kitty +kitten ssh";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Safety nets
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

      # Nix shortcuts
      ns = "nix-shell";
      nb = "nix build";
      ne = "nix-env";
      nsu = "nix-shell --run";
    };

    # History configuration
    history = {
      size = 100000;
      save = 100000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    initContent = ''
      # Better history search
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Ctrl+Arrow keys for word navigation
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word

      # Better completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu select

      # Kitty shell integration
      if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
        export KITTY_SHELL_INTEGRATION="enabled"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      fi

      # Quick directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      setopt PUSHD_SILENT

      # Better globbing
      setopt EXTENDED_GLOB
      setopt GLOB_DOTS

      # No beeping
      unsetopt BEEP
    '';

    # Oh My Zsh plugins (if you want them)
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "macos"
        "sudo"
        "command-not-found"
        "dirhistory"
      ];
    };
  };

  # Additional shell tools
  home.packages = with pkgs; [
    zsh-history-substring-search
    zsh-completions
  ];
}
