{ pkgs, ... }:
let
  catppuccinLatte = {
    base = "#eff1f5";
    mantle = "#e6e9ef";
    crust = "#dce0e8";
    text = "#4c4f69";
    subtext0 = "#6c6f85";
    blue = "#1e66f5";
    lavender = "#7287fd";
    red = "#d20f39";
    peach = "#fe640b";
    green = "#40a02b";
    teal = "#179299";
    mauve = "#8839ef";
  };

  removeHash = s: builtins.substring 1 (builtins.stringLength s - 1) s;

  startupScript = pkgs.writeShellScriptBin "start" ''
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only text data
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store & # Stores only image data
  '';
  #      ${pkgs.hyprpaper}/bin/hyprpaper &
  #      ${pkgs.hyprpanel}/bin/hyprpanel &
  rofiPowerMenu = pkgs.writeShellScriptBin "rofi-power-menu" ''
    choice=$(printf ' Logout\n⏾ Suspend\n Reboot\n⏻ Shutdown' \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt="Power ")
    case "$choice" in
      ' Logout')   ${pkgs.hyprland}/bin/hyprctl dispatch exit ;;
      '⏾ Suspend') ${pkgs.systemd}/bin/systemctl suspend ;;
      ' Reboot')   ${pkgs.systemd}/bin/systemctl reboot ;;
      '⏻ Shutdown') ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';
in
{
  # Install required packages
  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    cliphist
    brightnessctl
    rofiPowerMenu
  ];

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "tray"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
        };

        memory = {
          format = " {}%";
          interval = 5;
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          states = {
            warning = 30;
            critical = 15;
          };
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ifname}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 10;
        };

        "custom/power" = {
          format = "⏻";
          on-click = "${rofiPowerMenu}/bin/rofi-power-menu";
          tooltip = false;
        };
      };
    };
    style = ''
      * {
        font-family: monospace;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background-color: ${catppuccinLatte.mantle};
        color: ${catppuccinLatte.text};
        border-bottom: 2px solid ${catppuccinLatte.crust};
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 8px;
      }

      #workspaces button {
        padding: 0 6px;
        background-color: transparent;
        color: ${catppuccinLatte.subtext0};
        border-bottom: 2px solid transparent;
      }

      #workspaces button:hover {
        background-color: ${catppuccinLatte.crust};
        color: ${catppuccinLatte.text};
      }

      #workspaces button.active {
        color: ${catppuccinLatte.blue};
        border-bottom: 2px solid ${catppuccinLatte.blue};
        font-weight: bold;
      }

      #workspaces button.focused {
        color: ${catppuccinLatte.lavender};
        border-bottom: 2px solid ${catppuccinLatte.lavender};
      }

      #clock {
        color: ${catppuccinLatte.text};
        padding: 0 8px;
      }

      #battery {
        color: ${catppuccinLatte.green};
        padding: 0 8px;
      }

      #battery.warning {
        color: ${catppuccinLatte.peach};
      }

      #battery.critical {
        color: ${catppuccinLatte.red};
        font-weight: bold;
      }

      #network {
        color: ${catppuccinLatte.teal};
        padding: 0 8px;
      }

      #pulseaudio {
        color: ${catppuccinLatte.mauve};
        padding: 0 8px;
      }

      #cpu {
        color: ${catppuccinLatte.blue};
        padding: 0 8px;
      }

      #memory {
        color: ${catppuccinLatte.lavender};
        padding: 0 8px;
      }

      #tray {
        padding: 0 8px;
        spacing: 8px;
      }

      #custom-power {
        color: ${catppuccinLatte.base};
        background-color: ${catppuccinLatte.red};
        padding: 0 12px;
        font-size: 15px;
        font-weight: bold;
      }

      #custom-power:hover {
        background-color: ${catppuccinLatte.peach};
      }
    '';
  };

  services.mako = {
    enable = true;
    settings = {
      background-color = catppuccinLatte.base;
      text-color = catppuccinLatte.text;
      border-color = catppuccinLatte.lavender;
      progress-color = "over #ccd0da";
      "urgency=low" = {
        border-color = catppuccinLatte.text;
      };
      "urgency=high" = {
        border-color = catppuccinLatte.red;
      };
    };
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.kitty}/bin/kitty";
        icons-enabled = "yes";
        width = 50;
        font = "monospace:size=13";
        line-height = 25;
        lines = 10;
        letter-spacing = 0;
      };
      colors = {
        background = "${removeHash catppuccinLatte.base}ff";
        text = "${removeHash catppuccinLatte.text}ff";
        match = "${removeHash catppuccinLatte.lavender}ff";
        selection = "${removeHash catppuccinLatte.lavender}ff";
        selection-text = "${removeHash catppuccinLatte.base}ff";
        border = "${removeHash catppuccinLatte.lavender}ff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    #    plugins = [
    #      inputs.hyprland-plugins.packages."${pkgs.stdenv.hostPlatform.system}".borders-plus-plus
    #    ];

    settings = {
      general = {
        "col.active_border" = "rgb(7287fd)"; # Catppuccin Latte lavender
        "col.inactive_border" = "rgb(ccd0da)"; # Catppuccin Latte surface0
      };

      input = {
        kb_options = "compose:ralt";
      };

      exec-once = "${startupScript}/bin/start";
      #       "[workspace 1 silent] firefox"
      #       "[workspace 5 silent] kitty btm"

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
        "$mainMod, S, exec, fuzzel"
        "$mainMod, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"

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

        "$mainMod, Escape, exec, ${rofiPowerMenu}/bin/rofi-power-menu"
      ];

      binde = [
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"

        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];
      #      "plugin:borders-plus-plus" = {
      #        add_borders = 1;
      #        "col.border_1" = "rgb(ffffff)";
      #        "col.border_2" = "rgb(2222ff)";
      #        border_size_1 = 10;
      #        border_size_2 = -1;
      #        natural_rounding = "yes";
      #      };
    };
  };
}
