_: {
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;

      General = {
        RememberLastDatabases = true;
        OpenPreviousDatabasesOnStartup = true;
        LastOpenedDatabases = "/home/dan/Dropbox/FreieMusik/Binarpilot - Nordland -- Jamendo - MP3 VBR 192k - 2010.10.05 [www.jamendo.com]/Readme - binarpilot.kdbx";
      };

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
