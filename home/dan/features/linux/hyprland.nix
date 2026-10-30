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
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = $ws, monitor = \"$monitor\" })"
      done

      hyprctl dispatch 'hl.dsp.focus({ workspace = 1 })'
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
      ' Logout')   ${pkgs-unstable.hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()' ;;
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
      hyprpicker
      playerctl
      swaybg
      rofiPowerMenu
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs-unstable.hyprland;
      systemd.enable = true;

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
          {
            name = "float-audio-mixer";
            float = true;
            center = true;
            size = "760 520";
            no_anim = true;
            match.class = "^(audio-mixer)$";
          }
          {
            name = "float-bluetooth-manager";
            float = true;
            center = true;
            size = "760 520";
            no_anim = true;
            match.class = "^(bluetooth-manager)$";
          }
        ];

        # The launcher (fuzzel) is a layer surface and would otherwise take the
        # layers open/close animation; a menu that is asked for should appear
        # and disappear without sliding or fading.
        layer_rule = [
          {
            name = "no-anim-launcher";
            no_anim = true;
            match.namespace = "^(launcher)$";
          }
        ];

        on = [
          (luaStart "${startupScript}/bin/start")
          (luaStart "${assign-workspaces}/bin/assign-workspaces")
          # Draw the Stylix image on every output; nothing else paints it.
          (luaStart "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill")
          # Volume and brightness overlays (swayosd-client sends to this).
          (luaStart "${pkgs.swayosd}/bin/swayosd-server")
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

          # Resize (ALT; CTRL and SHIFT are already used for monitor/workspace
          # moves) and swap windows in the layout.
          (luaRepeatBind "${mainMod} + ALT + h" "hl.dsp.window.resize({ x = -40, y = 0, relative = true })")
          (luaRepeatBind "${mainMod} + ALT + l" "hl.dsp.window.resize({ x = 40, y = 0, relative = true })")
          (luaRepeatBind "${mainMod} + ALT + k" "hl.dsp.window.resize({ x = 0, y = -40, relative = true })")
          (luaRepeatBind "${mainMod} + ALT + j" "hl.dsp.window.resize({ x = 0, y = 40, relative = true })")
          (luaBind "${mainMod} + SHIFT + ALT + h" ''hl.dsp.window.swap({ direction = "left" })'')
          (luaBind "${mainMod} + SHIFT + ALT + l" ''hl.dsp.window.swap({ direction = "right" })'')
          (luaBind "${mainMod} + SHIFT + ALT + k" ''hl.dsp.window.swap({ direction = "up" })'')
          (luaBind "${mainMod} + SHIFT + ALT + j" ''hl.dsp.window.swap({ direction = "down" })'')

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

          # Window cycling (ALT+Tab; the main modifier owns Tab for monitors)
          (luaBind "ALT + Tab" "hl.dsp.window.cycle_next()")
          (luaBind "ALT + SHIFT + Tab" "hl.dsp.window.cycle_next({ next = false })")

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

          # Scratchpad: park any window on a named special workspace
          (luaBind "${mainMod} + grave" ''hl.dsp.workspace.toggle_special("scratchpad")'')
          (luaBind "${mainMod} + SHIFT + grave" ''hl.dsp.window.move({ workspace = "special:scratchpad" })'')

          # Monitor focus cycling
          (luaBind "${mainMod} + Tab" ''hl.dsp.focus({ monitor = "+1" })'')
          (luaBind "${mainMod} + SHIFT + Tab" ''hl.dsp.focus({ monitor = "-1" })'')

          # Move workspace to monitor
          (luaBind "${mainMod} + CTRL + l" ''hl.dsp.workspace.move({ monitor = "+1" })'')
          (luaBind "${mainMod} + CTRL + h" ''hl.dsp.workspace.move({ monitor = "-1" })'')

          # Rotate the focused monitor 90° clockwise (transform 0→1→2→3→0).
          # Hyprland reflows neighbours, but the bars of the other outputs keep
          # their old position, so waybar is reloaded to re-anchor them. Reload
          # is SIGUSR2; SIGUSR1 toggles bar visibility in waybar 0.15.0, and
          # sending it hid the whole bar until the next rotate.
          (luaBind "${mainMod} + CTRL + r" ''
            function()
              local m = hl.get_active_monitor()
              if m == nil then return end
              hl.monitor({ output = m.name, transform = (m.transform + 1) % 4 })
              hl.exec_cmd("sleep 0.3; pkill -USR2 waybar")
            end
          '')

          # Screenshot: region selection → clipboard
          (luaBind "${mainMod} + Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy")'')

          # Screenshot annotation with satty
          (luaBind "${mainMod} + SHIFT + Print" ''hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty -f -")'')
          (luaBind "${mainMod} + ALT + Print" ''hl.dsp.exec_cmd("grim - | satty -f -")'')

          # Colour picker: copy the pixel under the cursor as hex. P would
          # re-introduce the withdrawn SHIFT+P move-to-workspace chord.
          (luaBind "${mainMod} + SHIFT + C" ''hl.dsp.exec_cmd("hyprpicker -a")'')

          # Screen recording with wf-recorder (toggle: stop if running, else start)
          (luaBind "${mainMod} + F9" ''hl.dsp.exec_cmd("pkill wf-recorder || wf-recorder -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4")'')
          (luaBind "${mainMod} + SHIFT + F9" ''hl.dsp.exec_cmd("pkill wf-recorder || wf-recorder -g \"$(slurp)\" -f ~/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4")'')

          # Lock screen. SUPER+L cannot be used: SUPER+l is focus right and
          # SUPER+SHIFT+l moves the window right.
          (luaBind "${mainMod} + backspace" ''hl.dsp.exec_cmd("hyprlock")'')
          (luaBind "${mainMod} + ALT + Escape" ''hl.dsp.exec_cmd("hyprlock")'')

          # Power menu
          (luaBind "${mainMod} + Escape" ''hl.dsp.exec_cmd("${rofiPowerMenu}/bin/rofi-power-menu")'')

          # Audio and brightness go through swayosd-client so every change is
          # also drawn as an OSD by the swayosd-server started above.
          (luaBind "XF86AudioMute" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle")'')
          (luaBind "XF86AudioMicMute" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle")'')

          # Repeating volume/brightness keys
          (luaRepeatBind "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume -5")'')
          (luaRepeatBind "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --output-volume +5")'')
          (luaRepeatBind "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --brightness -5")'')
          (luaRepeatBind "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("${pkgs.swayosd}/bin/swayosd-client --brightness +5")'')
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
