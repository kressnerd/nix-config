{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    vscode.fhs
  ];
}
