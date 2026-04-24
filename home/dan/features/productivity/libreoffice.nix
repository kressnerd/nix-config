{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    libreoffice
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [ ".config/libreoffice" ];
}
