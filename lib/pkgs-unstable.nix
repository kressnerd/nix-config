{
  nixpkgs-unstable,
  system,
}:
import nixpkgs-unstable {
  inherit system;
  config.allowUnfree = true;
}
