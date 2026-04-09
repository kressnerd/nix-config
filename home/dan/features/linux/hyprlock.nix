{ lib, ... }:
{
  # Stylix themes Hyprlock colors and background: do not set background here
  stylix.targets.hyprlock.enable = true;

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 5; # seconds grace period after lock before requiring password
      };
      input-field = lib.mkForce [
        {
          size = "250, 50";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          fade_on_empty = true;
          placeholder_text = "Password...";
          position = "0, -80";
          halign = "center";
          valign = "center";
        }
      ];
      label = lib.mkForce [
        {
          text = "cmd[update:1000] date +\"%H:%M\"";
          font_size = 64;
          font_family = "Inter";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
