{ pkgs, ... }:
{
  # Infrastructure authoring tools for the personal laptop.
  # The GitHub client is installed as a package only: no `programs.gh`, so no
  # git credential helper is registered (the device keeps its own identity
  # selection; see the change `infrastructure-authoring-tooling`, D1).
  home.packages = with pkgs; [
    opentofu # OpenTofu infrastructure-as-code engine
    gh # GitHub command-line client
  ];
}
