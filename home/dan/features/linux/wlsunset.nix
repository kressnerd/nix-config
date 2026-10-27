{ pkgs, lib, ... }:
let
  # Berlin city-center coordinates (public/city-level precision, acceptable for personal config)
  lat = "52.52";
  lon = "13.40";
  cmd = "wlsunset -l ${lat} -L ${lon}";
  luaInline = lib.generators.mkLuaInline;
in
{
  home.packages = [ pkgs.wlsunset ];

  wayland.windowManager.hyprland.settings = {
    on = [
      {
        _args = [
          "hyprland.start"
          (luaInline "function() hl.exec_cmd(${builtins.toJSON cmd}) end")
        ];
      }
    ];
    bind = [
      {
        _args = [
          "SUPER + SHIFT + N"
          (luaInline "hl.dsp.exec_cmd(${builtins.toJSON "pkill wlsunset || ${cmd}"})")
        ];
      }
    ];
  };
}
