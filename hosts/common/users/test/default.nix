{config, ...}: {
#  imports = [./packages.nix];

  users.mutableUsers = false;
  users.users.test = {
    isNormalUser = true;
    description = "Non-sudo account for testing new config options that could break login.";
    extraGroups = [
      "wheel"
    ];
    hashedPasswordFile = config.sops.secrets."users/test/hashed_pwd".path;
#    hashedPasswordFile = config.sops.secrets.test-password.path;
  };

  sops.secrets.test-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  # Persist entire home
  environment.persistence = {
    "/persist".directories = ["/home/test"];
  };
}
