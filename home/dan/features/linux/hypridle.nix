_: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
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
          timeout = 900; # 15 minutes — suspend
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
