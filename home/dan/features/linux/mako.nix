{ pkgs, ... }:
{
  stylix.targets.mako.enable = true;

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      border-radius = 8;
      border-size = 2;
      max-visible = 3;
      default-timeout = 5000;
      icons = true;
      icon-path = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Light";
      max-icon-size = 32;
      icon-border-radius = 4;
      margin = "8";
      padding = "12";
    };
  };
}
