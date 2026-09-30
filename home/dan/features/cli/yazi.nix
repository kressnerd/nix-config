{
  config,
  lib,
  ...
}:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    # Home Manager 26.05 changed the default from "yy" to "y", but keeps the
    # legacy default while home.stateVersion < 26.05. Set explicitly so the
    # shell wrapper is "y" regardless of stateVersion.
    shellWrapperName = "y";
  };

  stylix.targets.yazi.enable = true;

  home = lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [
      ".local/share/yazi"
    ];
  };
}
