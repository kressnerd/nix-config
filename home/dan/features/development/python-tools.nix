{ pkgs, ... }:
{
  home.packages = with pkgs; [
    uv # Python package manager (provides uvx)
  ];
}
