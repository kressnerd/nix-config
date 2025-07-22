{ pkgs, ... }:

{
  programs.keepassxc.enable = true;
  programs.librewolf.enable = true;

  home.packages = with pkgs; [
    jetbrains-toolbox
  ];
}
