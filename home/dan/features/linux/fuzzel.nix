_: {
  stylix.targets.fuzzel.enable = true;

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        width = 35;
        lines = 10;
        horizontal-pad = 12;
        vertical-pad = 8;
        icons-enabled = "no";
        anchor = "center";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
