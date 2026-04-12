{ config, lib, ... }:
{
  users.users.dan = {
    isNormalUser = true;
    description = lib.mkDefault "Dan";
    extraGroups = [ "wheel" ] ++ lib.optional config.networking.networkmanager.enable "networkmanager";
  };
}
