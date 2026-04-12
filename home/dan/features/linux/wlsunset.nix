{ pkgs, ... }:
let
  # Brussels city-center coordinates (public/city-level precision, acceptable for personal config)
  lat = "50.85";
  lon = "4.35";
  cmd = "wlsunset -l ${lat} -L ${lon}";
in
{
  home.packages = [ pkgs.wlsunset ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [ cmd ];
    bind = [
      "SUPER SHIFT, N, exec, pkill wlsunset || ${cmd}"
    ];
  };
}
