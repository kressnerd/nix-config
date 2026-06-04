{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs; [
      libreoffice
    ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [ ".config/libreoffice" ];
  })
]
