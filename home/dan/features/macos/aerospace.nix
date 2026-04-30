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

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-q = "workspace 1";
        alt-w = "workspace 2";
        alt-e = "workspace 3";
        alt-r = "workspace 4";
        alt-t = "workspace 5";
        alt-y = "workspace 6";
        alt-u = "workspace 7";
        alt-i = "workspace 8";
        alt-o = "workspace 9";

        alt-shift-q = "move-node-to-workspace 1";
        alt-shift-w = "move-node-to-workspace 2";
        alt-shift-e = "move-node-to-workspace 3";
        alt-shift-r = "move-node-to-workspace 4";
        alt-shift-t = "move-node-to-workspace 5";
        alt-shift-y = "move-node-to-workspace 6";
        alt-shift-u = "move-node-to-workspace 7";
        alt-shift-i = "move-node-to-workspace 8";
        alt-shift-o = "move-node-to-workspace 9";

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
