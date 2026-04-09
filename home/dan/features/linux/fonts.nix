{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    font-awesome # Waybar icons (Nerd Font glyphs)
    nerd-fonts.symbols-only # Fallback nerd font symbol glyphs
  ];
}
