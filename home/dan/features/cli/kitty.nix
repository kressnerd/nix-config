{ pkgs, ... }:
let
  mod = if pkgs.stdenv.isDarwin then "cmd" else "ctrl+shift";
  modShift = if pkgs.stdenv.isDarwin then "cmd+shift" else "ctrl+alt";
in
{
  programs.kitty = {
    enable = true;

    themeFile = "Catppuccin-Latte";

    settings = {
      # Font configuration
      font_family = "JetBrainsMono Nerd Font Mono";
      font_size = "12.0";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Window settings
      window_padding_width = 10;
      hide_window_decorations = if pkgs.stdenv.isDarwin then "titlebar-only" else "no";
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

    # Key mappings — mod = cmd (macOS) or ctrl+shift (Linux)
    keybindings = {
      # Tabs
      "${mod}+t" = "new_tab";
      "${mod}+w" = "close_tab";
      "${mod}+]" = "next_tab";
      "${mod}+[" = "previous_tab";
      "${mod}+1" = "goto_tab 1";
      "${mod}+2" = "goto_tab 2";
      "${mod}+3" = "goto_tab 3";
      "${mod}+4" = "goto_tab 4";
      "${mod}+5" = "goto_tab 5";

      # Splits — modShift = cmd+shift (macOS) or ctrl+alt (Linux)
      "${mod}+d" = "launch --location=vsplit";
      "${modShift}+d" = "launch --location=hsplit";
      "${modShift}+]" = "next_window";
      "${modShift}+[" = "previous_window";

      # Font size
      "${mod}+plus" = "change_font_size all +2.0";
      "${mod}+minus" = "change_font_size all -2.0";
      "${mod}+0" = "change_font_size all 0";

      # Clear
      "${mod}+k" = "clear_terminal clear active";
    };

    extraConfig = ''
      # Custom shortcuts
      map ${modShift}+e open_url_with_hints

      # SSH shortcuts
      map ${modShift}+s launch --type=tab ssh myserver
    '';
  };

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
