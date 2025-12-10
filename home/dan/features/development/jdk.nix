{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    zulu
    maven
  ];
}
