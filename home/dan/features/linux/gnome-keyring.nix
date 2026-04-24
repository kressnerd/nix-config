{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  # secret-tool CLI — used by infra/http/httpyac.config.js to read tokens from gnome-keyring
  home.packages = [ pkgs.libsecret ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [ ".local/share/keyrings" ];
}
