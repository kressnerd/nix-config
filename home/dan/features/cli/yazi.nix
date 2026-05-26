{
  config,
  lib,
  ...
}:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };

  stylix.targets.yazi.enable = true;

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [
        ".local/share/yazi"
      ];
}
