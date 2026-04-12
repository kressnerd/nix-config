{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../common/global
    ../common/users/dan.nix
    ./hardware.nix
    ./options.nix
    inputs.sops-nix.nixosModules.sops
    inputs.impermanence.nixosModules.impermanence
    ../../tests/assertions
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  nixpkgs.hostPlatform = "x86_64-linux";

  networking = {
    hostName = "cupix001";
    firewall.enable = true;
  };

  # SOPS secrets configuration
  # Age key derived from SSH host key (Option A from plan)
  # The key path is on /persist to survive impermanence root wipes
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };

  system.stateVersion = "25.11";
}
