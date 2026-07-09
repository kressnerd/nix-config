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

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      gaps = {
        inner = {
          horizontal = 2;
          vertical = 2;
        };
        outer = {
          top = 2;
          bottom = 2;
          left = 2;
          right = 2;
        };
      };

      on-window-detected = [
        # Workspace 1-WWW: Browser
        {
          "if".app-id = "com.google.Chrome";
          run = "move-node-to-workspace 1-WWW";
        }
        {
          "if".app-id = "com.apple.Safari";
          run = "move-node-to-workspace 1-WWW";
        }
        {
          "if".app-id = "org.mozilla.firefox";
          run = "move-node-to-workspace 1-WWW";
        }
        # Workspace 2-TTY: Terminals
        {
          "if".app-id = "org.alacritty";
          run = "move-node-to-workspace 2-TTY";
        }
        {
          "if".app-id = "com.googlecode.iterm2";
          run = "move-node-to-workspace 2-TTY";
        }
        {
          "if".app-id = "com.apple.Terminal";
          run = "move-node-to-workspace 2-TTY";
        }
        {
          "if".app-id = "net.kovidgoyal.kitty";
          run = "move-node-to-workspace 2-TTY";
        }
        # Workspace 3-IDE: IDEs
        {
          "if".app-id = "com.jetbrains.intellij";
          run = "move-node-to-workspace 3-IDE";
        }
        {
          "if".app-id = "com.microsoft.VSCode";
          run = "move-node-to-workspace 3-IDE";
        }
        {
          "if".app-id = "com.sublimetext.4";
          run = "move-node-to-workspace 3-IDE";
        }
        # Workspace 4-MSG: Chat
        {
          "if".app-id = "com.microsoft.teams2";
          run = "move-node-to-workspace 4-MSG";
        }
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = "move-node-to-workspace 4-MSG";
        }
        # Workspace 5-MAIL: Email
        {
          "if".app-id = "com.microsoft.Outlook";
          run = "move-node-to-workspace 5-MAIL";
        }
      ];

      mode.main.binding = {
        # Focus — vim-style hjkl (cross-monitor)
        alt-h = "focus left --boundaries all-monitors-outer-frame";
        alt-j = "focus down --boundaries all-monitors-outer-frame";
        alt-k = "focus up --boundaries all-monitors-outer-frame";
        alt-l = "focus right --boundaries all-monitors-outer-frame";

        # Cyclic window focus in workspace (dfs-next/dfs-prev)
        alt-tab = "focus --boundaries-action wrap-around-the-workspace dfs-next";
        alt-shift-tab = "focus --boundaries-action wrap-around-the-workspace dfs-prev";

        # Focus monitor — cycle between monitors
        alt-backtick = "focus-monitor --wrap-around next";
        alt-shift-backtick = "focus-monitor --wrap-around prev";

        # Move window — shift+hjkl
        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        # Move workspace to monitor
        alt-ctrl-l = "move-workspace-to-monitor --wrap-around next";
        alt-ctrl-h = "move-workspace-to-monitor --wrap-around prev";

        # Fullscreen (maximize)
        alt-f = "fullscreen";

        # Layout toggles
        alt-semicolon = "layout tiles horizontal vertical";
        alt-slash = "layout accordion horizontal vertical";
        alt-space = "layout floating tiling";

        # Launchers
        alt-d = "exec-and-forget open -a Raycast || open -a Spotlight";
        alt-enter = "exec-and-forget open -na kitty";
        alt-t = "exec-and-forget open -a Marta";

        # Workspaces 1–6 (named)
        alt-1 = "workspace 1-WWW";
        alt-2 = "workspace 2-TTY";
        alt-3 = "workspace 3-IDE";
        alt-4 = "workspace 4-MSG";
        alt-5 = "workspace 5-MAIL";
        alt-6 = "workspace 6-AGNT";

        # Workspace cycle (keypad replacement)
        alt-leftSquareBracket = "workspace --wrap-around prev";
        alt-rightSquareBracket = "workspace --wrap-around next";

        # Move node to workspace 1–6 (named)
        alt-shift-1 = "move-node-to-workspace 1-WWW";
        alt-shift-2 = "move-node-to-workspace 2-TTY";
        alt-shift-3 = "move-node-to-workspace 3-IDE";
        alt-shift-4 = "move-node-to-workspace 4-MSG";
        alt-shift-5 = "move-node-to-workspace 5-MAIL";
        alt-shift-6 = "move-node-to-workspace 6-AGNT";

        # Service mode
        alt-shift-semicolon = "mode service";
      };

      mode.service.binding = {
        # Reload config and return to main mode
        esc = [
          "reload-config"
          "mode main"
        ];
        # Flatten workspace tree (fixes narrow-window chaos)
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        # Toggle floating
        f = [
          "layout floating tiling"
          "mode main"
        ];
      };
    };
  };
}
