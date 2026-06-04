{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs; [
      owncloud-client
    ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [
      ".config/ownCloud"
      ".local/share/ownCloud"
    ];
  })
]
