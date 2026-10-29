{ pkgs, pkgs-unstable, ... }:
let
  # Hyprland reads every dispatch request as Lua (`hl.dispatch(<args>)`), so the
  # text dispatchers waybar 0.15.0 sends ("dispatch workspace 3") are parse
  # errors: a click on a workspace number reaches the module and then does
  # nothing. Upstream fixed that on master only (e17c0d9f0a..0f12de9319,
  # unreleased as of 0.15.0, 2026-02-06); carry the port until a release has it.
  waybar = pkgs.waybar.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/waybar-hyprland-lua-dispatch.patch ];
  });

  rofiPowerMenu = pkgs.writeShellScriptBin "rofi-power-menu" ''
    choice=$(printf ' Logout\n Reboot\n⏻ Shutdown' \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt="Power ")
    case "$choice" in
      ' Logout')   ${pkgs-unstable.hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()' ;;
      ' Reboot')   ${pkgs.systemd}/bin/systemctl reboot ;;
      '⏻ Shutdown') ${pkgs.systemd}/bin/systemctl poweroff ;;
    esac
  '';
in
{
  home.packages = [ rofiPowerMenu ];

  stylix.targets.waybar.enable = true;

  programs.waybar = {
    enable = true;
    package = waybar;
    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M · %Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 muted";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pulsemixer";
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-disconnected = "󰤭 ";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          format-charging = "󰂄 {capacity}%";
          states = {
            warning = 30;
            critical = 15;
          };
        };

        tray = {
          spacing = 8;
        };

        "custom/power" = {
          format = "⏻";
          on-click = "${rofiPowerMenu}/bin/rofi-power-menu";
          tooltip = false;
        };
      };
    };
    style = ''
      /* Stylix provides @define-color base00..base0F and sets * { color, background } */

      window#waybar {
        background: alpha(@base00, 0.95);
      }

      .modules-left,
      .modules-center,
      .modules-right {
        background: alpha(@base01, 0.8);
        border-radius: 16px;
        padding: 0 8px;
        margin: 4px 4px;
      }

      #workspaces button {
        padding: 0 6px;
        border-radius: 12px;
        min-width: 20px;
        color: @base04;
      }

      #workspaces button.active {
        color: @base0D;
        background: alpha(@base02, 0.6);
      }

      #clock {
        font-weight: bold;
      }

      #pulseaudio,
      #network,
      #battery,
      #tray,
      #custom-power {
        padding: 0 8px;
      }

      #battery.charging {
        color: @base0B;
      }

      #battery.warning:not(.charging) {
        color: @base09;
      }

      #battery.critical:not(.charging) {
        color: @base08;
      }

      #custom-power {
        padding: 0 4px 0 8px;
      }
    '';
  };
}
