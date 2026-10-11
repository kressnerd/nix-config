{ pkgs-unstable, ... }:
{
  # omp (Oh My Pi) — terminal-based coding agent with multi-model support.
  # Only available in nixpkgs-unstable (absent from stable 26.05), so it is
  # pulled from pkgs-unstable. Config, auth and sessions live under ~/.omp;
  # that directory is persisted via impermanence (see
  # modules/home-manager/persistence/default.nix).
  home.packages = [ pkgs-unstable.omp ];
}
