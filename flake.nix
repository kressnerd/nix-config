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

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
      sops-nix,
      mac-app-util,
      nix-homebrew,
      nur,
      disko,
      colmena,
      stylix,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      overlays.default = import ./overlays;

      templates = {
        host = {
          path = ./templates/host;
          description = "New NixOS host scaffold";
        };
      };

      nixosConfigurations = {
        nixos-vm-minimal = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs outputs;
            pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
              inherit nixpkgs-unstable;
              system = "aarch64-linux";
            };
          };
          modules = [
            {
              nixpkgs.overlays = [
                nur.overlays.default
                (import ./overlays)
              ];
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
                  pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
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
            pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
              inherit nixpkgs-unstable;
              system = "x86_64-linux";
            };
          };
          modules = [
            {
              nixpkgs.overlays = [
                nur.overlays.default
                (import ./overlays)
              ];
              nixpkgs.config.allowUnfree = true;
            }
            ./hosts/thiniel
            stylix.nixosModules.stylix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs outputs;
                  pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
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
      };

      darwinConfigurations = {
        J6G6Y9JK7L = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit inputs outputs;
            pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
              inherit nixpkgs-unstable;
              system = "aarch64-darwin";
            };
          };
          modules = [
            {
              nixpkgs.overlays = [
                nur.overlays.default
                (import ./overlays)
              ];
              nixpkgs.config.allowUnfree = true;
            }
            mac-app-util.darwinModules.default
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/J6G6Y9JK7L
            stylix.darwinModules.stylix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs outputs;
                  pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
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

      # ── Dev shells ─────────────────────────────────────────────────────────
      devShells = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value =
              let
                pkgs = nixpkgs.legacyPackages.${system};
              in
              {
                default = pkgs.mkShell {
                  NIX_CONFIG = "extra-experimental-features = nix-command flakes";
                  nativeBuildInputs = [
                    pkgs.nix
                    pkgs.home-manager
                    pkgs.git
                    pkgs.python3
                    pkgs.python3Packages.requests
                    pkgs.python3Packages.pytest
                  ];
                };
              };
          })
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ]
      );

      # ── Formatter (nix fmt) ────────────────────────────────────────────────
      formatter = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
          })
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ]
      );

      # ── Test checks ──────────────────────────────────────────────────────
      checks =
        let
          allSystems = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ];
          linuxSystems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          forSystems =
            systems: f:
            builtins.listToAttrs (
              map (system: {
                name = system;
                value = f system;
              }) systems
            );
        in
        nixpkgs.lib.recursiveUpdate
          (forSystems allSystems (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              unit-helpers = import ./tests/unit/default.nix { inherit pkgs; };

              lint-deadnix =
                pkgs.runCommand "lint-deadnix"
                  {
                    src = self;
                    nativeBuildInputs = [ pkgs.deadnix ];
                  }
                  ''
                    deadnix --fail $src
                    touch $out
                  '';

              lint-statix =
                pkgs.runCommand "lint-statix"
                  {
                    src = self;
                    nativeBuildInputs = [ pkgs.statix ];
                  }
                  ''
                    statix check $src
                    touch $out
                  '';

              lint-nixfmt =
                pkgs.runCommand "lint-nixfmt"
                  {
                    src = self;
                    nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
                  }
                  ''
                    find $src -name '*.nix' -not -path '*/result*' -exec nixfmt --check {} +
                    touch $out
                  '';
            }
          ))
          (
            forSystems linuxSystems (
              system:
              let
                pkgs = nixpkgs.legacyPackages.${system};
                integrationTests = import ./tests/integration/default.nix { inherit pkgs; };
              in
              integrationTests
            )
          );

      colmenaHive = colmena.lib.makeHive {
        meta = {
          # Default nixpkgs for x86_64-linux nodes.
          # For aarch64-linux nodes, override per node:
          #   nodeNixpkgs.<hostname> = import nixpkgs { system = "aarch64-linux"; ... };
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              nur.overlays.default
              (import ./overlays)
            ];
            config.allowUnfree = true;
          };
          specialArgs = {
            inherit inputs outputs; # outputs is self-referential (same pattern as nixosConfigurations)
          };
          # Per-node specialArgs for arch-specific pkgs-unstable:
          # nodeSpecialArgs.<hostname> = { pkgs-unstable = ...; };
        };
        # Nodes are added here after initial provisioning via nixos-anywhere.
        # Example:
        # my-server = {
        #   imports = [ ./hosts/my-server ];
        #   deployment = {
        #     targetHost = "my-server.example.com";
        #     targetUser = "dan";
        #     tags = [ "server" ];
        #   };
        # };
      };
    };
}
