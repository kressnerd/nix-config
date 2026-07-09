{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.stylix.enable;
      message = "J6G6Y9JK7L: stylix must be enabled";
    }
    {
      assertion = config.stylix.polarity == "light";
      message = "J6G6Y9JK7L: stylix polarity must be light, got ${config.stylix.polarity}";
    }
    {
      assertion = config.stylix.base16Scheme.base00 == "fafafa";
      message = "J6G6Y9JK7L: stylix base16 scheme base00 must be One Light background (fafafa), got ${config.stylix.base16Scheme.base00}";
    }
    {
      assertion = config.programs.aerospace.enable;
      message = "aerospace: programs.aerospace.enable must be true — import features/macos/aerospace.nix";
    }
    {
      assertion =
        let
          settings = config.programs.aerospace.userSettings;
        in
        !(builtins.hasAttr "workspace-to-monitor-force-assignment" settings);
      message = "aerospace: workspace-to-monitor-force-assignment must be absent — dynamic monitor assignment";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-h" bindings
        && builtins.match ".*all-monitors-outer-frame.*" bindings."alt-h" != null;
      message = "aerospace: alt-h focus must use --boundaries all-monitors-outer-frame for cross-monitor navigation";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-tab" bindings && builtins.match ".*dfs-next.*" bindings."alt-tab" != null;
      message = "aerospace: alt-tab must be bound to dfs-next (cyclic window focus in workspace)";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-backtick" bindings
        && bindings."alt-backtick" == "focus-monitor --wrap-around next";
      message = "aerospace: alt-backtick must be bound to focus-monitor --wrap-around next";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-ctrl-l" bindings
        && bindings."alt-ctrl-l" == "move-workspace-to-monitor --wrap-around next";
      message = "aerospace: alt-ctrl-l must be bound to move-workspace-to-monitor --wrap-around next";
    }
    {
      assertion =
        let
          settings = config.programs.aerospace.userSettings;
        in
        builtins.hasAttr "on-focused-monitor-changed" settings
        && settings."on-focused-monitor-changed" == [ "move-mouse monitor-lazy-center" ];
      message = "aerospace: on-focused-monitor-changed must move mouse to monitor center";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-1" bindings && bindings."alt-1" == "workspace 1-WWW";
      message = "aerospace: alt-1 must switch to named workspace 1-WWW";
    }
    {
      assertion =
        let
          settings = config.programs.aerospace.userSettings;
        in
        builtins.hasAttr "on-window-detected" settings && builtins.length settings.on-window-detected > 0;
      message = "aerospace: on-window-detected rules must be configured for auto-placement";
    }
    {
      assertion =
        let
          bindings = config.programs.aerospace.userSettings.mode.main.binding;
        in
        builtins.hasAttr "alt-t" bindings && builtins.match ".*Marta.*" bindings."alt-t" != null;
      message = "aerospace: alt-t must open Marta";
    }
    # --- global ---
    {
      assertion = builtins.any (p: lib.getName p == "htop") config.home.packages;
      message = "global: htop must be installed";
    }
    # --- cli/ansible ---
    {
      assertion = builtins.any (p: lib.getName p == "ansible-core") config.home.packages;
      message = "J6G6Y9JK7L: ansible must be installed — import features/cli/ansible.nix";
    }
    # --- cli/cloud-tools ---
    {
      assertion = builtins.any (p: lib.getName p == "google-cloud-sdk") config.home.packages;
      message = "cloud-tools: google-cloud-sdk must be installed";
    }
    # --- cli/deploy-tools ---
    {
      assertion = builtins.any (p: lib.getName p == "colmena") config.home.packages;
      message = "deploy-tools: colmena must be installed";
    }
    # --- cli/git ---
    {
      assertion = config.programs.git.enable;
      message = "git: programs.git.enable must be true";
    }
    # --- cli/kitty ---
    {
      assertion = config.programs.kitty.enable;
      message = "kitty: programs.kitty.enable must be true";
    }
    # --- cli/shell-utils ---
    {
      assertion = builtins.any (p: lib.getName p == "lazygit") config.home.packages;
      message = "shell-utils: lazygit must be installed";
    }
    # --- cli/sops ---
    {
      assertion = builtins.any (p: lib.getName p == "age") config.home.packages;
      message = "sops: age must be installed";
    }
    # --- cli/ssh ---
    {
      assertion = config.programs.ssh.enable;
      message = "ssh: programs.ssh.enable must be true";
    }
    # --- cli/starship ---
    {
      assertion = config.programs.starship.enable;
      message = "starship: programs.starship.enable must be true";
    }
    # --- cli/vim ---
    {
      assertion = config.programs.vim.enable;
      message = "vim: programs.vim.enable must be true";
    }
    # --- cli/yazi ---
    {
      assertion = config.programs.yazi.enable;
      message = "yazi: programs.yazi.enable must be true";
    }
    # --- cli/fish ---
    {
      assertion = config.programs.fish.enable;
      message = "fish: programs.fish.enable must be true";
    }
    # --- development/containers ---
    {
      assertion = builtins.any (p: lib.getName p == "podman") config.home.packages;
      message = "containers: podman must be installed";
    }
    # --- development/formatters ---
    {
      assertion = builtins.any (p: lib.getName p == "nixfmt") config.home.packages;
      message = "formatters: nixfmt-rfc-style must be installed";
    }
    # --- development/go ---
    {
      assertion = builtins.any (p: lib.getName p == "go") config.home.packages;
      message = "go: go must be installed";
    }
    # --- development/python-tools ---
    {
      assertion = builtins.any (p: lib.getName p == "uv") config.home.packages;
      message = "python-tools: uv must be installed";
    }
    # --- development/nodejs ---
    {
      assertion = builtins.any (p: lib.getName p == "nodejs") config.home.packages;
      message = "nodejs: nodejs must be installed";
    }
    # --- development/fnm ---
    {
      assertion = builtins.any (p: lib.getName p == "fnm") config.home.packages;
      message = "fnm: fnm must be installed";
    }
    # --- development/opencode ---
    {
      assertion = builtins.any (p: lib.getName p == "opencode") config.home.packages;
      message = "opencode: opencode must be installed";
    }
    # --- productivity/browser ---
    {
      assertion = config.programs.firefox.enable;
      message = "browser: programs.firefox.enable must be true";
    }
    # --- productivity/firefox-company ---
    {
      assertion = config.programs.firefox.profiles ? "company";
      message = "firefox-company: company Firefox profile must be configured";
    }
    # --- productivity/mac-tools ---
    {
      assertion = builtins.any (p: lib.getName p == "utm") config.home.packages;
      message = "mac-tools: utm must be installed";
    }
    # --- productivity/emacs-doom ---
    {
      assertion = config.fonts.fontconfig.enable;
      message = "emacs-doom: fonts.fontconfig.enable must be true";
    }
  ];
}
