{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    owncloud-client
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [
        ".config/ownCloud"
        ".local/share/ownCloud"
      ];
}
