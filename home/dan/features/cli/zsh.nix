{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    # Common aliases
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
    };

    initContent = ''
      # Custom zsh configuration
    '';
  };
}
