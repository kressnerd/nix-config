{
  config,
  lib,
  pkgs-unstable,
  ...
}:
{
  home.packages = with pkgs-unstable; [
    claude-code
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [ ".claude" ];
}
