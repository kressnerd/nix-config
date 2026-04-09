{ pkgs, pkgs-unstable, ... }:
let
  startupScript = pkgs.writeShellScriptBin "start" ''
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only text data
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only image data
  '';
  rofiPowerMenu = pkgs.writeShellScriptBin "rofi-power-menu" ''
    choice=$(printf ' Logout\n⏾ Suspend\n Reboot\n⏻ Shutdown' \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt="Power ")
    case "$choice" in
      ' Logout')   ${pkgs-unstable.hyprland}/bin/hyprctl dispatch exit ;;
      '⏾ Suspend') ${pkgs.systemd}/bin/systemctl suspend ;;
      ' Reboot')   ${pkgs.systemd}/bin/systemctl reboot ;;
      '⏻ Shutdown') ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';
in
{
  # Stylix handles border colors from the base16 scheme automatically
  stylix.targets.hyprland.enable = true;

  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    cliphist
    brightnessctl
    grim
    slurp
    rofiPowerMenu
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;

    settings = {
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur.enabled = false;
        shadow.enabled = false;
      };

      animations = {
        enabled = true;
        animation = [
          "windows, 1, 3, default, slide"
          "windowsOut, 1, 3, default, slide"
          "fade, 1, 3, default"
          "workspaces, 1, 3, default, slide"
        ];
      };

      input = {
        kb_options = "compose:ralt";
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
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

      windowrulev2 = [
        "float, class:^(dialog)$"
        "float, title:^(Open File)(.*)$"
        "float, title:^(Select a File)(.*)$"
        "float, title:^(Choose wallpaper)(.*)$"
        "float, title:^(Open Folder)(.*)$"
        "float, title:^(Save As)(.*)$"
        "pin, title:^(Picture-in-Picture)$"
        "idleinhibit fullscreen, class:.*"
      ];

      "$mainMod" = "SUPER";

      bind = [
        # Terminal
        "$mainMod, Return, exec, kitty"

        # Window management
        "$mainMod, Q, killactive,"
        "$mainMod, F, fullscreen, 1"
        "$mainMod SHIFT, F, fullscreen, 0"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, S, togglesplit,"

        # Launcher
        "$mainMod, D, exec, fuzzel"

        # Clipboard history
        "$mainMod SHIFT, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

        # Focus: vim-style
        "$mainMod, h, movefocus, l"
        "$mainMod, l, movefocus, r"
        "$mainMod, k, movefocus, u"
        "$mainMod, j, movefocus, d"

        # Move windows: vim-style with Shift
        "$mainMod SHIFT, h, movewindow, l"
        "$mainMod SHIFT, l, movewindow, r"
        "$mainMod SHIFT, k, movewindow, u"
        "$mainMod SHIFT, j, movewindow, d"

        # Workspace switching
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

        # Move window to workspace
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

        # Screenshot: region selection → clipboard
        "$mainMod, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Lock screen
        "$mainMod, backspace, exec, hyprlock"

        # Power menu
        "$mainMod, Escape, exec, ${rofiPowerMenu}/bin/rofi-power-menu"

        # Audio
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
