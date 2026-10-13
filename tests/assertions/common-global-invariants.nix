# tests/assertions/common-global-invariants.nix
# Universal NixOS module assertions for hosts/common/global/ — enforced at evaluation time via nix flake check
# No hostname guard — applies to all NixOS hosts
{ config, lib, ... }:
{
  config = {
    assertions = [
      {
        assertion = config.time.timeZone == "Europe/Berlin";
        message = "Global invariant violated: time.timeZone must be Europe/Berlin";
      }
      {
        assertion = config.i18n.defaultLocale == "en_US.UTF-8";
        message = "Global invariant violated: i18n.defaultLocale must be en_US.UTF-8";
      }
      {
        assertion = builtins.elem "flakes" config.nix.settings.experimental-features;
        message = "Global invariant violated: nix flakes experimental feature must be enabled";
      }
      {
        assertion = builtins.elem "nix-command" config.nix.settings.experimental-features;
        message = "Global invariant violated: nix-command experimental feature must be enabled";
      }
      {
        assertion = builtins.elem "@wheel" config.nix.settings.trusted-users;
        message = "nix: trusted-users must include @wheel (required for remote nixos-rebuild deployments)";
      }
      {
        # A program on the device may rewrite a file the home profile renders (the
        # browser rewrites its profile registry and search state). Without a
        # displacement command Home Manager refuses the foreign file and aborts the
        # activation; see the change `managed-file-displacement`.
        assertion =
          config.home-manager.backupCommand != null
          && lib.hasInfix "hm-displace-managed-file" (toString config.home-manager.backupCommand);
        message = "Global invariant violated: home-manager.backupCommand must be the repository's displacement command, so a rewritten managed file is renamed aside instead of aborting the activation";
      }
    ];
  };
}
