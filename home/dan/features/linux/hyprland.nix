{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  startupScript = pkgs.writeShellScriptBin "start" ''
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only text data
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only image data
  '';
  assign-workspaces = pkgs.writeShellScriptBin "assign-workspaces" ''
    set -euo pipefail
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.socat
        pkgs-unstable.hyprland
      ]
    }:$PATH"

    assign_workspaces() {
      local monitors count idx monitor
      monitors=($(hyprctl monitors -j | jq -r '.[].name'))
      count=''${#monitors[@]}

      if [ "$count" -eq 0 ]; then
        return
      fi

      for ws in $(seq 1 10); do
        idx=$(( (ws - 1) % count ))
        monitor="''${monitors[$idx]}"
        hyprctl dispatch moveworkspacetomonitor "$ws" "$monitor"
      done

      hyprctl dispatch workspace 1
    }

    sleep 2
    assign_workspaces

    # Long-running listener — relax strict mode for resilience
    set +e
    while true; do
      SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
      socat -U - UNIX-CONNECT:"$SOCKET" | while IFS= read -r line; do
        case "$line" in
          monitoradded*|monitorremoved*)
            sleep 3
            assign_workspaces
            ;;
        esac
      done
      sleep 2  # backoff before reconnect
    done
  '';
  rofiPowerMenu = pkgs.writeShellScriptBin "rofi-power-menu" ''
    choice=$(printf ' Logout\n Reboot\n⏻ Shutdown' \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt="Power ")
    case "$choice" in
      ' Logout')   ${pkgs-unstable.hyprland}/bin/hyprctl dispatch exit ;;
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
    satty
    wf-recorder
    rofiPowerMenu
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs-unstable.hyprland;
    systemd.enable = true;

    settings = {
      env = [
        "AQ_NO_MODIFIERS,1"
      ];

      general = {
        gaps_in = 2;
        gaps_out = 2;
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
        kb_layout = "us";
        kb_variant = "altgr-intl";
        kb_model = "pc105";
        kb_options = "terminate:ctrl_alt_bksp";
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      gesture = "3, horizontal, workspace";

      exec-once = [
        "${startupScript}/bin/start"
        "${assign-workspaces}/bin/assign-workspaces"
      ];

      monitor = [
        ", preferred, auto, 1"
        "eDP-1, preferred, 0x0, 1"
      ];

      windowrule = [
        {
          name = "float-dialog";
          float = true;
          "match:class" = "^(dialog)$";
        }
        {
          name = "float-open-file";
          float = true;
          "match:title" = "^(Open File)(.*)$";
        }
        {
          name = "float-select-file";
          float = true;
          "match:title" = "^(Select a File)(.*)$";
        }
        {
          name = "float-wallpaper";
          float = true;
          "match:title" = "^(Choose wallpaper)(.*)$";
        }
        {
          name = "float-open-folder";
          float = true;
          "match:title" = "^(Open Folder)(.*)$";
        }
        {
          name = "float-save-as";
          float = true;
          "match:title" = "^(Save As)(.*)$";
        }
        {
          name = "pin-pip";
          pin = true;
          "match:title" = "^(Picture-in-Picture)$";
        }
        {
          name = "idleinhibit-full";
          idle_inhibit = "fullscreen";
          "match:class" = ".*";
        }
        {
          name = "opacity-zathura";
          opacity = "1.0 override 1.0 override";
          "match:class" = "^(org.pwmt.zathura)$";
        }
        {
          name = "opacity-mpv";
          opacity = "1.0 override 1.0 override";
          "match:class" = "^(mpv)$";
        }
      ];

      "$mainMod" = "SUPER";

      bind = [
        # Terminal
        "$mainMod, Return, exec, kitty"

        # Window management
        "$mainMod, C, killactive,"
        "$mainMod, F, fullscreen, 1"
        "$mainMod SHIFT, F, fullscreen, 0"
        "$mainMod, V, togglefloating,"
        "$mainMod, G, pseudo,"
        "$mainMod, semicolon, layoutmsg, togglesplit"

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
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move window to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Monitor focus cycling
        "$mainMod, Tab, focusmonitor, +1"
        "$mainMod SHIFT, Tab, focusmonitor, -1"

        # Move workspace to monitor
        "$mainMod CTRL, l, movecurrentworkspacetomonitor, +1"
        "$mainMod CTRL, h, movecurrentworkspacetomonitor, -1"

        # Screenshot: region selection → clipboard
        "$mainMod, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Screenshot annotation with satty
        "$mainMod SHIFT, Print, exec, grim -g \"$(slurp)\" - | satty -f -"
        "$mainMod ALT, Print, exec, grim - | satty -f -"

        # Screen recording with wf-recorder (toggle: stop if running, else start)
        "$mainMod, F9, exec, pkill wf-recorder || wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
        "$mainMod SHIFT, F9, exec, pkill wf-recorder || wf-recorder -g \"$(slurp)\" -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"

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

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [
        "Videos"
      ];
}
