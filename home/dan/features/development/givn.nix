{ pkgs, ... }:
{
  # givn: from buster/givn flake overlay (private repo, pinned via flake.lock).
  home.packages = [ pkgs.givn ];
}
