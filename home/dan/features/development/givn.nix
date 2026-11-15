{
  pkgs,
  ...
}:
{
  # givn: from the public flake's overlay (`github:buster/givn`).
  home.packages = [ pkgs.givn ];
}
