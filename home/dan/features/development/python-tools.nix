{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python3 # Python 3 interpreter
    uv # Python package manager (provides uvx)
  ];
}
