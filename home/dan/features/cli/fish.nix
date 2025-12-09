{
  config,
  pkgs,
  lib,
  ...
}: {
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

      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
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

      # Better completion colors
      set -g fish_color_command green
      set -g fish_color_error red
      set -g fish_color_param cyan
      set -g fish_color_quote yellow
      set -g fish_color_redirection magenta
      set -g fish_color_end blue
      set -g fish_color_autosuggestion brblack
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
