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

  mainMod = "SUPER";

  luaInline = lib.generators.mkLuaInline;

  luaBind = key: dispatcher: {
    _args = [
      key
      (luaInline dispatcher)
    ];
  };

  luaRepeatBind = key: dispatcher: {
    _args = [
      key
      (luaInline dispatcher)
      { repeating = true; }
    ];
  };

  luaStart = command: {
    _args = [
      "hyprland.start"
      (luaInline "function() hl.exec_cmd(${builtins.toJSON command}) end")
    ];
  };
in
lib.mkMerge [
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

      # Hyprland 0.56 deprecates the hyprlang `.conf` format, and 0.57 removes
      # it. configType "lua" makes Home Manager generate hyprland.lua, so the
      # settings below use Hyprland's Lua call form (hl.config, hl.bind, ...).
      configType = "lua";

      settings = {
        env = [
          {
            _args = [
              "AQ_NO_MODIFIERS"
              "1"
            ];
          }
        ];

        config = {
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

          animations.enabled = true;

          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";
            kb_model = "pc105";
            kb_options = "terminate:ctrl_alt_bksp";
            touchpad = {
              natural_scroll = true;
              tap_to_click = true;
            };
          };
        };

        animation = [
          {
            leaf = "windows";
            enabled = true;
            speed = 3;
            bezier = "default";
            style = "slide";
          }
          {
            leaf = "windowsOut";
            enabled = true;
            speed = 3;
            bezier = "default";
            style = "slide";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 3;
            bezier = "default";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 3;
            bezier = "default";
            style = "slide";
          }
        ];

        gesture = {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        };

        monitor = [
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = 1;
          }
          {
            output = "eDP-1";
            mode = "preferred";
            position = "0x0";
            scale = 1;
          }
        ];

        window_rule = [
          {
            name = "float-dialog";
            float = true;
            match.class = "^(dialog)$";
          }
          {
            name = "float-open-file";
            float = true;
            match.title = "^(Open File)(.*)$";
          }
          {
            name = "float-select-file";
            float = true;
            match.title = "^(Select a File)(.*)$";
          }
          {
            name = "float-wallpaper";
            float = true;
            match.title = "^(Choose wallpaper)(.*)$";
          }
          {
            name = "float-open-folder";
            float = true;
            match.title = "^(Open Folder)(.*)$";
          }
          {
            name = "float-save-as";
            float = true;
            match.title = "^(Save As)(.*)$";
          }
          {
            name = "pin-pip";
            pin = true;
            match.title = "^(Picture-in-Picture)$";
          }
          {
            name = "idleinhibit-full";
            idle_inhibit = "fullscreen";
            match.class = ".*";
          }
          {
            name = "opacity-zathura";
            opacity = "1.0 override 1.0 override";
            match.class = "^(org.pwmt.zathura)$";
          }
          {
            name = "opacity-mpv";
            opacity = "1.0 override 1.0 override";
            match.class = "^(mpv)$";
          }
        ];

        on = [
          (luaStart "${startupScript}/bin/start")
          (luaStart "${assign-workspaces}/bin/assign-workspaces")
        ];

        bind = [
          # Terminal
          (luaBind "${mainMod} + Return" ''hl.dsp.exec_cmd("kitty")'')

          # Window management
          (luaBind "${mainMod} + C" "hl.dsp.window.close()")
          (luaBind "${mainMod} + F" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
          (luaBind "${mainMod} + SHIFT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
          (luaBind "${mainMod} + V" ''hl.dsp.window.float({ action = "toggle" })'')
          (luaBind "${mainMod} + G" "hl.dsp.window.pseudo()")
          (luaBind "${mainMod} + semicolon" ''hl.dsp.layout("togglesplit")'')

          # Launcher
          (luaBind "${mainMod} + D" ''hl.dsp.exec_cmd("fuzzel")'')

          # Clipboard history
          (luaBind "${mainMod} + SHIFT + V" ''hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy")'')

          # Focus: vim-style
          (luaBind "${mainMod} + h" ''hl.dsp.focus({ direction = "left" })'')
          (luaBind "${mainMod} + l" ''hl.dsp.focus({ direction = "right" })'')
          (luaBind "${mainMod} + k" ''hl.dsp.focus({ direction = "up" })'')
          (luaBind "${mainMod} + j" ''hl.dsp.focus({ direction = "down" })'')

          # Move windows: vim-style with Shift
          (luaBind "${mainMod} + SHIFT + h" ''hl.dsp.window.move({ direction = "left" })'')
          (luaBind "${mainMod} + SHIFT + l" ''hl.dsp.window.move({ direction = "right" })'')
          (luaBind "${mainMod} + SHIFT + k" ''hl.dsp.window.move({ direction = "up" })'')
          (luaBind "${mainMod} + SHIFT + j" ''hl.dsp.window.move({ direction = "down" })'')

          # Workspace switching
          (luaBind "${mainMod} + 1" "hl.dsp.focus({ workspace = 1 })")
          (luaBind "${mainMod} + 2" "hl.dsp.focus({ workspace = 2 })")
          (luaBind "${mainMod} + 3" "hl.dsp.focus({ workspace = 3 })")
          (luaBind "${mainMod} + 4" "hl.dsp.focus({ workspace = 4 })")
          (luaBind "${mainMod} + 5" "hl.dsp.focus({ workspace = 5 })")
          (luaBind "${mainMod} + 6" "hl.dsp.focus({ workspace = 6 })")
          (luaBind "${mainMod} + 7" "hl.dsp.focus({ workspace = 7 })")
          (luaBind "${mainMod} + 8" "hl.dsp.focus({ workspace = 8 })")
          (luaBind "${mainMod} + 9" "hl.dsp.focus({ workspace = 9 })")
          (luaBind "${mainMod} + 0" "hl.dsp.focus({ workspace = 10 })")

          # Move window to workspace
          (luaBind "${mainMod} + SHIFT + 1" "hl.dsp.window.move({ workspace = 1 })")
          (luaBind "${mainMod} + SHIFT + 2" "hl.dsp.window.move({ workspace = 2 })")
          (luaBind "${mainMod} + SHIFT + 3" "hl.dsp.window.move({ workspace = 3 })")
          (luaBind "${mainMod} + SHIFT + 4" "hl.dsp.window.move({ workspace = 4 })")
          (luaBind "${mainMod} + SHIFT + 5" "hl.dsp.window.move({ workspace = 5 })")
          (luaBind "${mainMod} + SHIFT + 6" "hl.dsp.window.move({ workspace = 6 })")
          (luaBind "${mainMod} + SHIFT + 7" "hl.dsp.window.move({ workspace = 7 })")
          (luaBind "${mainMod} + SHIFT + 8" "hl.dsp.window.move({ workspace = 8 })")
          (luaBind "${mainMod} + SHIFT + 9" "hl.dsp.window.move({ workspace = 9 })")
          (luaBind "${mainMod} + SHIFT + 0" "hl.dsp.window.move({ workspace = 10 })")

          # Monitor focus cycling
          (luaBind "${mainMod} + Tab" ''hl.dsp.focus({ monitor = "+1" })'')
          (luaBind "${mainMod} + SHIFT + Tab" ''hl.dsp.focus({ monitor = "-1" })'')

          # Move workspace to monitor
          (luaBind "${mainMod} + CTRL + l" ''hl.dsp.workspace.move({ monitor = "+1" })'')
          (luaBind "${mainMod} + CTRL + h" ''hl.dsp.workspace.move({ monitor = "-1" })'')

          # Screenshot: region selection → clipboard
          (luaBind "${mainMod} + Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'')

          # Screenshot annotation with satty
          (luaBind "${mainMod} + SHIFT + Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty -f -")'')
          (luaBind "${mainMod} + ALT + Print" ''hl.dsp.exec_cmd("grim - | satty -f -")'')

          # Screen recording with wf-recorder (toggle: stop if running, else start)
          (luaBind "${mainMod} + F9" ''hl.dsp.exec_cmd("pkill wf-recorder || wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4")'')
          (luaBind "${mainMod} + SHIFT + F9" ''hl.dsp.exec_cmd("pkill wf-recorder || wf-recorder -g \"$(slurp)\" -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4")'')

          # Lock screen
          (luaBind "${mainMod} + backspace" ''hl.dsp.exec_cmd("hyprlock")'')

          # Power menu
          (luaBind "${mainMod} + Escape" ''hl.dsp.exec_cmd("${rofiPowerMenu}/bin/rofi-power-menu")'')

          # Audio
          (luaBind "XF86AudioMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'')
          (luaBind "XF86AudioMicMute" ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'')

          # Repeating volume/brightness keys
          (luaRepeatBind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'')
          (luaRepeatBind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")'')
          (luaRepeatBind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("brightnessctl set 5%-")'')
          (luaRepeatBind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("brightnessctl set 5%+")'')
        ];
      };
    };

  }
  (lib.mkIf config.myHome.persistence.enable {
    home.persistence.${config.myHome.persistence.root}.directories = [
      "Videos"
    ];
  })
]
