{
  config,
  pkgs,
  ...
}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    font-awesome
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
    nerd-fonts.symbols-only
    nerd-fonts.fira-code
    wl-clipboard
    cliphist
  ];
}
