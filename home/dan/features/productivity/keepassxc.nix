_: {
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;

      GUI = {
        AdvancedSettings = true;
        ApplicationTheme = "classic";
        CompactMode = true;
        HidePasswords = true;
      };

      SSHAgent.Enabled = true;
    };
  };
}
