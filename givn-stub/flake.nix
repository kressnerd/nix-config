{
  description = "Stub for the overridable `givn` input: no outputs, so public evaluation and CI need no access to the private tool flake.";

  # The root flake follows this input's nixpkgs to `nixpkgs-unstable`. Keeping
  # the input declaration makes the same follows rule valid for the real flake
  # supplied by a deploy override.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  # No `overlays` output: consumers apply the overlay only when the overridden
  # input provides one. See flake.nix and home/dan/features/development/givn.nix.
  outputs = _: { };
}
