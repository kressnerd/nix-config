{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    maestral
  ];

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [
        "Dropbox"
        ".config/maestral"
        ".local/share/maestral"
      ];

  systemd.user.services.maestral = {
    Unit = {
      Description = "Maestral Dropbox client";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.maestral}/bin/maestral start --foreground";
      ExecStop = "${pkgs.maestral}/bin/maestral stop";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
