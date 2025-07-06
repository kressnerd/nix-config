{
  description = "Dan's nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

  };

  outputs = { self, nixpkgs, darwin, home-manager, mac-app-util, ... }@inputs: {
    darwinConfigurations."J6G6Y9JK7L" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        mac-app-util.darwinModules.default
        ./hosts/J6G6Y9JK7L
        home-manager.darwinModules.home-manager
        (
          { pkgs, config, inputs, ... }:
          {
            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];
          }
        )
      ];
    };
  };
}
