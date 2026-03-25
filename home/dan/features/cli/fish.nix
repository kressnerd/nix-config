{pkgs, ...}: {
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      lt = "eza --tree";

      g = "git";
      gs = "git status";

      v = "vim";
      vi = "vim";

      icat = "kitty +kitten icat";
      ssh = "kitty +kitten ssh";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };

    interactiveShellInit = ''
      # Disable greeting
      set fish_greeting

      # Kitty shell integration
      if set -q KITTY_INSTALLATION_DIR
        set --prepend fish_function_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_functions.d"
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
      end

      # Catppuccin Latte colors
      set -g fish_color_normal "#4c4f69"
      set -g fish_color_command "#1e66f5"
      set -g fish_color_keyword "#8839ef"
      set -g fish_color_quote "#40a02b"
      set -g fish_color_redirection "#ea76cb"
      set -g fish_color_end "#179299"
      set -g fish_color_error "#d20f39"
      set -g fish_color_param "#4c4f69"
      set -g fish_color_comment "#9ca0b0"
      set -g fish_color_operator "#04a5e5"
      set -g fish_color_escape "#ea76cb"
      set -g fish_color_autosuggestion "#9ca0b0"
      set -g fish_color_cancel "#d20f39"
      set -g fish_pager_color_prefix "#7287fd" --bold
      set -g fish_pager_color_completion "#4c4f69"
      set -g fish_pager_color_description "#df8e1d"
      set -g fish_pager_color_selected_background --background="#ccd0da"
    '';

    functions = {
      gs = "git status";

      mkcd = "mkdir -p $argv[1]; and cd $argv[1]";
    };

    plugins = [
      # Fish plugin manager alternatives would go here
    ];
  };

  # Additional packages for fish (keeping minimal to avoid broken plugins)
  home.packages = with pkgs; [
    fishPlugins.sdkman-for-fish
  ];
}
