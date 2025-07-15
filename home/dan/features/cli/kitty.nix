{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.kitty = {
    enable = true;

    themeFile = "Catppuccin-Latte";

    settings = {
      # Font configuration
      font_family = "JetBrainsMono Nerd Font";
      font_size = "12.0";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Window settings
      window_padding_width = 10;
      hide_window_decorations =
        if pkgs.stdenv.isDarwin
        then "titlebar-only"
        else "no";
      confirm_os_window_close = 0;

      # Tab bar
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;

      # macOS specific
      macos_option_as_alt = true;
      macos_quit_when_last_window_closed = false;
      macos_traditional_fullscreen = false;

      # Scrollback
      scrollback_lines = 10000;

      # URLs
      url_style = "single";
      open_url_with = "default";

      # Cursor
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "15.0";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
    };

    # Key mappings
    keybindings = {
      # Tabs
      "cmd+t" = "new_tab";
      "cmd+w" = "close_tab";
      "cmd+]" = "next_tab";
      "cmd+[" = "previous_tab";
      "cmd+1" = "goto_tab 1";
      "cmd+2" = "goto_tab 2";
      "cmd+3" = "goto_tab 3";
      "cmd+4" = "goto_tab 4";
      "cmd+5" = "goto_tab 5";

      # Splits
      "cmd+d" = "launch --location=vsplit";
      "cmd+shift+d" = "launch --location=hsplit";
      "cmd+shift+]" = "next_window";
      "cmd+shift+[" = "previous_window";

      # Font size
      "cmd+plus" = "change_font_size all +2.0";
      "cmd+minus" = "change_font_size all -2.0";
      "cmd+0" = "change_font_size all 0";

      # Clear
      "cmd+k" = "clear_terminal clear active";
    };

    extraConfig = ''
      # Add any additional config here

      # Example: Custom shortcuts for specific tasks
      map cmd+shift+e open_url_with_hints

      # Example: SSH shortcuts
      map cmd+shift+s launch --type=tab ssh myserver
    '';
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
