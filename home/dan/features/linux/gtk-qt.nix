{ pkgs, ... }:
{
  # Enable Stylix targets for GTK and Qt theming
  stylix.targets.gtk.enable = true;
  stylix.targets.qt.enable = true;

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Light";
    };
  };

  qt = {
    enable = true;
    # Stylix handles Qt theming via kvantum/qt5ct/qt6ct
  };
}
