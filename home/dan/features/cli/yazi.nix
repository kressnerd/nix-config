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

  home = lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [
      ".local/share/yazi"
    ];
  };
}
