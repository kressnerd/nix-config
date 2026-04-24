{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    signal-desktop
    threema-desktop
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [
        ".config/Signal"
        ".config/Threema"
      ];
}
