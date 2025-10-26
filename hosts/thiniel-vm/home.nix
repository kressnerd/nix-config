{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  # Home Manager configuration integration for thiniel-vm
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs outputs;
    };

    users.dan = import ../../home/dan/thiniel-vm.nix;

    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];
  };

  # Ensure the dan user exists and has proper groups
  users.users.dan = {
    isNormalUser = true;
    description = "Me Myself and Billie";
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
  };

  # Enable ZSH system-wide since we're using it
  programs.zsh.enable = true;
}
