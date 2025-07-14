{ pkgs, ... }:

{
  programs.keepassxc.enable = true;

  home.packages = with pkgs; [
    jetbrains-toolbox # install IntelliJ Idea manually
  ];
}
