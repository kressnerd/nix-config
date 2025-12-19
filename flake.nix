{
  description = "Dan's Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    nur.url = "github:nix-community/NUR";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    score-spec-tap = {
      url = "github:score-spec/homebrew-tap";
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

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    darwin,
    home-manager,
    sops-nix,
    mac-app-util,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    nur,
    nixos-hardware,
    impermanence,
    firefox-addons,
    disko,
    nixos-anywhere,
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      nixos-vm-minimal = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs outputs;
          pkgs-unstable = import ./lib/pkgs-unstable.nix {
            inherit nixpkgs-unstable;
            system = "aarch64-linux";
          };
        };
        modules = [
          {
            nixpkgs.overlays = [nur.overlays.default];
            nixpkgs.config.allowUnfree = true;
          }
          ./hosts/nixos-vm-minimal
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs outputs;
                pkgs-unstable = import ./lib/pkgs-unstable.nix {
                  inherit nixpkgs-unstable;
                  system = "aarch64-linux";
                };
              };
              users.dan = import ./home/dan/nixos-vm-minimal.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };
      thiniel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
          pkgs-unstable = import ./lib/pkgs-unstable.nix {
            inherit nixpkgs-unstable;
            system = "x86_64-linux";
          };
        };
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
                pkgs-unstable = import ./lib/pkgs-unstable.nix {
                  inherit nixpkgs-unstable;
                  system = "x86_64-linux";
                };
              };
              users.dan = import ./home/dan/thiniel.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };

      thiniel-vm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux"; # Default to Apple Silicon, can be overridden
        specialArgs = {
          inherit inputs outputs;
          pkgs-unstable = import ./lib/pkgs-unstable.nix {
            inherit nixpkgs-unstable;
            system = "aarch64-linux";
          };
        };
        modules = [
          {
            nixpkgs.overlays = [nur.overlays.default];
            nixpkgs.config.allowUnfree = true;
          }
          ./hosts/thiniel-vm
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs outputs;
                pkgs-unstable = import ./lib/pkgs-unstable.nix {
                  inherit nixpkgs-unstable;
                  system = "aarch64-linux";
                };
              };
              users.dan = import ./home/dan/thiniel-vm.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };
    };

    darwinConfigurations = {
      J6G6Y9JK7L = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs;
          pkgs-unstable = import ./lib/pkgs-unstable.nix {
            inherit nixpkgs-unstable;
            system = "aarch64-darwin";
          };
        };
        modules = [
          {
            nixpkgs.overlays = [
              nur.overlays.default
            ];
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
                pkgs-unstable = import ./lib/pkgs-unstable.nix {
                  inherit nixpkgs-unstable;
                  system = "aarch64-darwin";
                };
              };
              users."daniel.kressner" = import ./home/dan/J6G6Y9JK7L.nix;
              sharedModules = [
                mac-app-util.homeManagerModules.default
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };
    };
  };
}
