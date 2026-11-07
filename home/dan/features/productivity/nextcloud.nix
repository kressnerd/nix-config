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

    # Nothing executes XDG autostart entries on this system: Hyprland has no
    # implementation, no xdg-desktop-autostart service runs, and the client's
    # own ~/.config/autostart entry is consequently never read. The unit is the
    # only thing that starts sync at login.
    systemd.user.services.nextcloud = {
      Unit = {
        Description = "Nextcloud desktop client";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.nextcloud-client}/bin/nextcloud --background";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [
      ".config/Nextcloud"
      ".local/share/Nextcloud"
      "owncl"
    ];
  })
]
