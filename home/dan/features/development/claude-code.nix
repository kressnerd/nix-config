{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    claude-code
  ];
}
