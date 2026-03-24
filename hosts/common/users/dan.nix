{lib, ...}: {
  users.users.dan = {
    isNormalUser = true;
    description = lib.mkDefault "Dan";
    extraGroups = ["wheel" "networkmanager"];
  };
}
