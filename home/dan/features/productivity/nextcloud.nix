{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs; [
      nextcloud-client
    ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [
      ".config/Nextcloud"
      ".local/share/Nextcloud"
      "owncl"
    ];
  })
]
