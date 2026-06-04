{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs; [
      signal-desktop
      threema-desktop
    ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [
      ".config/Signal"
      ".config/Threema"
    ];
  })
]
