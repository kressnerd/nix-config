{
  config,
  lib,
  pkgs-unstable,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs-unstable; [
      claude-code
    ];
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [ ".claude" ];
  })
]
