{ config, ... }:
{
  # Expose the sops-nix age key at the standard SOPS CLI discovery path so
  # `sops` works in every shell without SOPS_AGE_KEY_FILE being set.
  xdg.configFile."sops/age/keys.txt".source =
    config.lib.file.mkOutOfStoreSymlink "/var/lib/sops-nix/key.txt";
}
