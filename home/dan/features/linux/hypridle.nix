_: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
      };
      listener = [
        {
          timeout = 300; # 5 minutes — dim screen
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600; # 10 minutes — lock screen
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900; # 15 minutes — screen off (no suspend: OPAL SED FDE)
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
      ];
    };
  };
}
