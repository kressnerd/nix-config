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

  # Full mixer in a floating terminal: output/input device choice, per-app
  # streams, mute and fade. Hyprland floats it through the `float-audio-mixer`
  # window rule in hyprland.nix; kitty must not reuse the geometry it remembers
  # from the last ordinary terminal, or that memory wins over the rule's size.
  audioMixer = pkgs.writeShellScriptBin "audio-mixer" ''
    exec ${pkgs.kitty}/bin/kitty --class audio-mixer --title "Audio mixer" \
      --override remember_window_size=no \
      -e ${pkgs.pulsemixer}/bin/pulsemixer
  '';

  # NetworkManager's nmcli carries the Wi-Fi state; the chooser lives in the
  # repository so its parsing and connection flow are unit-tested.
  wifiMenuPy = pkgs.writers.writePython3Bin "wifi-menu" {
    # The module keeps its own shebang when executed from the repository, and
    # the repository's line length matches its pytest suite rather than the
    # writer's 79-column default.
    flakeIgnore = [
      "E265"
      "E501"
    ];
  } (builtins.readFile ../../../../scripts/wifi_menu.py);
  wifiMenu = pkgs.writeShellScriptBin "wifi-menu" ''
    WIFI_MENU_FUZZEL="''${WIFI_MENU_FUZZEL:-${pkgs.fuzzel}/bin/fuzzel}"
    WIFI_MENU_NMCLI="''${WIFI_MENU_NMCLI:-${pkgs.networkmanager}/bin/nmcli}"
    WIFI_MENU_NOTIFY="''${WIFI_MENU_NOTIFY:-${pkgs.libnotify}/bin/notify-send}"
    export WIFI_MENU_FUZZEL WIFI_MENU_NMCLI WIFI_MENU_NOTIFY
    exec ${wifiMenuPy}/bin/wifi-menu "$@"
  '';

  # bluetuith is a TUI; run it in a floating terminal like the audio mixer.
  bluetoothManager = pkgs.writeShellScriptBin "bluetooth-manager" ''
    exec ${pkgs.kitty}/bin/kitty --class bluetooth-manager --title "Bluetooth" \
      --override remember_window_size=no \
      -e ${pkgs.bluetuith}/bin/bluetuith
  '';
in
{
  home.packages = [
    rofiPowerMenu
    audioMixer
    wifiMenu
    bluetoothManager
  ];

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

        modules-left = [
          "hyprland/workspaces"
          "mpris"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "bluetooth"
          "battery"
          "idle_inhibitor"
          "temperature"
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
          scroll-step = 5;
          on-click = "${audioMixer}/bin/audio-mixer";
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-disconnected = "󰤭 ";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "${wifiMenu}/bin/wifi-menu";
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "󰝚";
            mpv = "󰐊";
            firefox = "󰈹";
            spotify = "󰓇";
          };
          status-icons = {
            playing = "󰐊";
            paused = "󰏤";
            stopped = "󰓛";
          };
          max-length = 40;
          tooltip-format = "{player} — {title}\n{artist}\n{album}";
          on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
          on-click-middle = "${pkgs.playerctl}/bin/playerctl previous";
          on-click-right = "${pkgs.playerctl}/bin/playerctl next";
          on-scroll-up = "${pkgs.playerctl}/bin/playerctl next";
          on-scroll-down = "${pkgs.playerctl}/bin/playerctl previous";
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {device_alias}";
          format-disabled = "󰂲";
          format-off = "󰂲";
          format-no-controller = "󰂲";
          tooltip-format = "{controller_alias} ({controller_address})";
          tooltip-format-connected = "{device_enumerate}";
          on-click = "${bluetoothManager}/bin/bluetooth-manager";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰈈";
            deactivated = "󰈉";
          };
          tooltip-format-activated = "Idle inhibition active";
          tooltip-format-deactivated = "Idle inhibition off";
        };

        temperature = {
          format = "󰔏 {temperatureC}°C";
          tooltip-format = "{temperatureC}°C";
          warning-threshold = 70;
          critical-threshold = 85;
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
      #bluetooth,
      #mpris,
      #idle_inhibitor,
      #temperature,
      #battery,
      #tray,
      #custom-power {
        padding: 0 8px;
      }

      /* Clickable modules had no feedback at all before. */
      #pulseaudio:hover,
      #network:hover,
      #bluetooth:hover,
      #mpris:hover,
      #idle_inhibitor:hover,
      #custom-power:hover {
        background: alpha(@base02, 0.8);
        border-radius: 12px;
      }

      #mpris.paused {
        color: @base04;
      }

      #idle_inhibitor.activated {
        color: @base0B;
      }

      #temperature.critical {
        color: @base08;
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
