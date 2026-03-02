{pkgs, ...}: {
  home.packages = with pkgs; [
    utm # Virtual machine host for macOS - excellent for running Linux/Windows VMs on Apple Silicon
    slack
  ];
}
