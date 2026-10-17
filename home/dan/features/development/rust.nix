{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      cargo
      clippy
      gcc
      pkg-config
      rustc
    ];
  }
  // lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [ ".cargo" ];
  };
}
