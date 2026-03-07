{pkgs, ...}: {
  home.packages = with pkgs; [
    sweethome3d.application
  ];
}
