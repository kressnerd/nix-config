{ pkgs, ... }:
let
  # Berlin city-center coordinates (public/city-level precision, acceptable for personal config)
  lat = "52.52";
  lon = "13.40";
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
