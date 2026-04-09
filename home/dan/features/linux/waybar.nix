{ pkgs, ... }:
let
  # Duplicated from hyprland.nix — will be replaced by Stylix tokens in Phase 7
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
  home.packages = [ rofiPowerMenu ];

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
}
