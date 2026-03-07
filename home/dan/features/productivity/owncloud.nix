{pkgs, ...}: {
  home.packages = with pkgs; [
    owncloud-client
  ];
}
