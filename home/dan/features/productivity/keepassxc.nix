{
  pkgs,
  lib,
  ...
}: {
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;

      GUI = {
        AdvancedSettings = true;
        ApplicationTheme = "dark";
        CompactMode = true;
        HidePasswords = true;
      };

      SSHAgent.Enabled = true;
    };
  };
}
