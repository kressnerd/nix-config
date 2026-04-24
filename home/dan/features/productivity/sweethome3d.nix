{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    sweethome3d.application
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [ ".eteks" ];
}
