{
  pkgs,
  config,
  lib,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.dan = {
    isNormalUser = true;
    description = "Me Myself and Billy";
    shell = pkgs.fish;
    extraGroups = ifTheyExist [
#      "audio"
#      "deluge"
#      "docker"
#      "git"
#      "i2c"
#      "libvirtd"
#      "lxd"
#      "minecraft"
#      "mysql"
#      "network"
#      "plugdev"
#      "podman"
#      "video"
      "wheel" # Enables 'sudo' for the user.
#      "wireshark"
    ];

    openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ../../../../home/dan/ssh.pub);
#    hashedPasswordFile = config.sops.secrets.dan-password.path;
    initialHashedPassword = "$6$.tIb37hYTPJeB13w$RSDaCkfYIEcxNn7Isct6XxeIS8mENfhx15XjDCuSlA4xrsCwAjZZuP7vp0xTmGBOAAZoGESsG4GT8eecpTASn/";

    packages = [pkgs.home-manager];
  };

  sops.secrets.dan-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.dan = import ../../../../home/dan/${config.networking.hostName}.nix;

#  security.pam.services = {
#    swaylock = {};
#  };
}
