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
        # Focus — vim-style hjkl
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        # Move window — shift+hjkl
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Fullscreen (maximize)
        alt-f = "fullscreen";

        # Layout toggle
        alt-semicolon = "layout tiles horizontal vertical";

        # Launcher (mirrors SUPER+D = fuzzel on Linux)
        alt-d = "exec-and-forget open -a Raycast || open -a Spotlight";

        # Terminal (mirrors SUPER+Return on Linux)
        alt-return = "exec-and-forget open -na kitty";

        # Workspaces 1–10 on number row
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # Move node to workspace 1–10
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        # Service mode
        alt-shift-semicolon = "mode service";
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
