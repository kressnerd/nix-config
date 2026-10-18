{
  givnAvailable,
  lib,
  pkgs,
  ...
}:
{
  # givn: from the private kressnerd/givn flake overlay. The public stub has no
  # overlay, so the package is installed only when a deploy supplies the real
  # input with --override-input givn github:kressnerd/givn.
  home.packages = lib.optionals givnAvailable [ pkgs.givn ];
}
