{
  config,
  pkgs,
  lib,
  ...
}: let
  startupScript = pkgs.writeShellScriptBin "start" ''
    ${pkgs.waybar}/bin/waybar &
    ${pkgs.mako}/bin/mako &
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store # Stores only text data
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store # Stores only image data
    sleep 1
  '';
in {
  # Install required packages
  home.packages = with pkgs; [
    waybar
    mako
    libnotify
    rofi-wayland
    wl-clipboard
    cliphist
    brightnessctl
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      input = {
        kb_options = "compose:ralt";
      };

      exec-once = "${startupScript}/bin/start";

      monitor = [
        ", preferred, auto, 1"
        "eDP-1, preferred, 0x0, 1"
        "DP-3, preferred, 4480x0, 1, transform, 1"
        "DP-4, preferred, 1920x0, 1"
      ];

      workspace = [
        "1,monitor:eDP-1,default:true"
        "2,monitor:eDP-1"
        "3,monitor:eDP-1"
        "4,monitor:eDP-1"
        "5,monitor:DP-6,default:true"
        "6,monitor:DP-6"
        "7,monitor:DP-6"
        "8,monitor:DP-3,default:true"
        "9,monitor:DP-3"
        "10,monitor:DP-3"
      ];

      "$mainMod" = "SUPER";

      bind = [
        "$mainMod, S, exec, rofi -show drun -show-icons"
        "$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        "$mainMod, F, fullscreen"
        "$mainMod, D, killactive,"
        "$mainMod, G, togglefloating,"

        "$mainMod, L, movefocus, r"
        "$mainMod, H, movefocus, l"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"
        "$mainMod CTRL, L, swapwindow, r"
        "$mainMod CTRL, H, swapwindow, l"
        "$mainMod CTRL, K, swapwindow, u"
        "$mainMod CTRL, J, swapwindow, d"

        "$mainMod, Q, workspace, 1"
        "$mainMod, W, workspace, 2"
        "$mainMod, E, workspace, 3"
        "$mainMod, R, workspace, 4"
        "$mainMod, T, workspace, 5"
        "$mainMod, Y, workspace, 6"
        "$mainMod, U, workspace, 7"
        "$mainMod, I, workspace, 8"
        "$mainMod, O, workspace, 9"
        "$mainMod, P, workspace, 10"

        "$mainMod SHIFT, Q, movetoworkspace, 1"
        "$mainMod SHIFT, W, movetoworkspace, 2"
        "$mainMod SHIFT, E, movetoworkspace, 3"
        "$mainMod SHIFT, R, movetoworkspace, 4"
        "$mainMod SHIFT, T, movetoworkspace, 5"
        "$mainMod SHIFT, Y, movetoworkspace, 6"
        "$mainMod SHIFT, U, movetoworkspace, 7"
        "$mainMod SHIFT, I, movetoworkspace, 8"
        "$mainMod SHIFT, O, movetoworkspace, 9"
        "$mainMod SHIFT, P, movetoworkspace, 10"

        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      binde = [
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"

        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];
    };
  };
}
