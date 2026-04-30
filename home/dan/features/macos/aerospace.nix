_: {
  programs.aerospace = {
    enable = true;
    launchd = {
      enable = true;
      keepAlive = true;
    };
    userSettings = {
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      key-mapping.preset = "qwerty";

      gaps = {
        inner = {
          horizontal = 4;
          vertical = 4;
        };
        outer = {
          top = 8;
          bottom = 8;
          left = 8;
          right = 8;
        };
      };

      mode.main.binding = {
        cmd-h = "focus left";
        cmd-j = "focus down";
        cmd-k = "focus up";
        cmd-l = "focus right";

        cmd-shift-h = "move left";
        cmd-shift-j = "move down";
        cmd-shift-k = "move up";
        cmd-shift-l = "move right";

        cmd-f = "fullscreen";
        cmd-s = "layout tiles horizontal vertical";
        cmd-return = "exec-and-forget open -na kitty";

        cmd-q = "workspace 1";
        cmd-w = "workspace 2";
        cmd-e = "workspace 3";
        cmd-r = "workspace 4";
        cmd-t = "workspace 5";
        cmd-y = "workspace 6";
        cmd-u = "workspace 7";
        cmd-i = "workspace 8";
        cmd-o = "workspace 9";
        cmd-p = "workspace 10";

        cmd-shift-q = "move-node-to-workspace 1";
        cmd-shift-w = "move-node-to-workspace 2";
        cmd-shift-e = "move-node-to-workspace 3";
        cmd-shift-r = "move-node-to-workspace 4";
        cmd-shift-t = "move-node-to-workspace 5";
        cmd-shift-y = "move-node-to-workspace 6";
        cmd-shift-u = "move-node-to-workspace 7";
        cmd-shift-i = "move-node-to-workspace 8";
        cmd-shift-o = "move-node-to-workspace 9";
        cmd-shift-p = "move-node-to-workspace 10";

        cmd-shift-semicolon = "mode service";
      };

      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
      };
    };
  };
}
