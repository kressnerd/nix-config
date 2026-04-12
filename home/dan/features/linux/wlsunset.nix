{ pkgs, ... }:
{
  home.packages = [ pkgs.wlsunset ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "wlsunset -l 50.85 -L 4.35"
    ];
    bind = [
      "SUPER SHIFT, N, exec, pkill wlsunset || wlsunset -l 50.85 -L 4.35"
    ];
  };
}
