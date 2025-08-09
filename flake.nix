{
  description = "Dan's nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    #    nixpkgs-dan-testing.url = "github:kressnerd/nixpkgs/roo-code-update";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    nur.url = "github:nix-community/NUR";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Doom Emacs integration
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Linux-specific inputs
    nixos-hardware.url = "github:NixOs/nixos-hardware/master";

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    # nixpkgs-dan-testing,
    darwin,
    home-manager,
    sops-nix,
    mac-app-util,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    nur,
    nix-doom-emacs-unstraightened,
    nixos-hardware,
    impermanence,
    hyprland,
    firefox-addons,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    # NixOS Configurations
    nixosConfigurations = {
      nixos-vm-minimal = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          {
            nixpkgs.overlays = [nur.overlays.default];
            nixpkgs.config.allowUnfree = true;
          }
          ./hosts/nixos-vm-minimal
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs outputs;
                pkgs-unstable = import nixpkgs-unstable {
                  system = "aarch64-linux";
                  config.allowUnfree = true;
                };
              };
              users.dan = import ./home/dan/nixos-vm-minimal.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
                inputs.nix-doom-emacs-unstraightened.homeModule
              ];
            };
          }
        ];
      };

      thiniel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          {
            nixpkgs.overlays = [nur.overlays.default];
            nixpkgs.config.allowUnfree = true;
          }
          ./hosts/thiniel
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs outputs;
                pkgs-unstable = import nixpkgs-unstable {
                  system = "x86_64-linux";
                  config.allowUnfree = true;
                };
              };
              users.dan = import ./home/dan/thiniel.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
                inputs.nix-doom-emacs-unstraightened.homeModule
              ];
            };
          }
        ];
      };
    };

    # Darwin Configurations
    darwinConfigurations = {
      J6G6Y9JK7L = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs outputs;};
        modules = [
          {
            nixpkgs.overlays = [nur.overlays.default];
            nixpkgs.config.allowUnfree = true;
          }
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          ./hosts/J6G6Y9JK7L
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs outputs;
                pkgs-unstable = import nixpkgs-unstable {
                  system = "aarch64-darwin";
                  config.allowUnfree = true;
                };
                #pkgs-dan-testing = import nixpkgs-dan-testing {
                #  system = "aarch64-darwin";
                #  config.allowUnfree = true;
                #};
              };
              users."daniel.kressner" = import ./home/dan/J6G6Y9JK7L.nix;
              sharedModules = [
                mac-app-util.homeManagerModules.default
                sops-nix.homeManagerModules.sops
                inputs.nix-doom-emacs-unstraightened.homeModule
              ];
            };
          }
        ];
      };
    };
  };
}
