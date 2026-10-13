{
  description = "Dan's Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # The coding agent's own pin. `nixpkgs-unstable` trails the agent's upstream
    # releases by days (18.8.4 on that branch against 18.10.0 on master, checked
    # 2026-10-13), and each device that carries the agent asserts a minimum
    # version, so the agent takes its package from a pin refreshed deliberately.
    # No other package uses this input; rationale and rejected alternatives are
    # in the change `current-omp-release`, design D1/D2.
    nixpkgs-agent.url = "github:NixOS/nixpkgs/master";

    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix-unstable = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nur.url = "github:nix-community/NUR";

    # Operational values (addresses, gateway, resolvers, ports) are supplied
    # through this overridable input. The public default is the in-tree stub,
    # which supplies nothing and asserts the host defaults are non-operational;
    # a deploy overrides it with the private flake:
    #   --override-input private git+file:///home/dan/dev/PRIVATE/nix-private
    # See docs/arc42/adr/ADR-0001-private-data-strategy.md.
    private.url = "path:./private-stub";

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

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
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

    givn = {
      url = "github:kressnerd/givn";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    mcp-nixos.url = "github:utensils/mcp-nixos";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
      home-manager-unstable,
      sops-nix,
      impermanence,
      mac-app-util,
      nix-homebrew,
      nur,
      disko,
      lanzaboote,
      colmena,
      stylix-unstable,
      mcp-nixos,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # The agent's package set, instantiated from its own pin. It is not part of
      # the repository's stable/unstable channel split: it exists for exactly one
      # package, whose version floor is asserted per device (`tests/assertions`).
      agentPkgsFor =
        system:
        import inputs.nixpkgs-agent {
          inherit system;
          config.allowUnfree = true;
        };
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
            impermanence.nixosModules.impermanence
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
                  ./modules/home-manager/persistence
                ];
              };
            }
          ];
        };
        thiniel = nixpkgs-unstable.lib.nixosSystem {
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
                inputs.givn.overlays.default
                (import ./overlays)
              ];
              nixpkgs.config.allowUnfree = true;
            }
            ./hosts/thiniel
            ./modules/home-manager/persistence/options.nix
            { myHome.persistence.enable = true; }
            stylix-unstable.nixosModules.stylix
            home-manager-unstable.nixosModules.home-manager
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
                  # The agent's package comes from its own pin (`nixpkgs-agent`),
                  # not from the unstable set the rest of the userland follows:
                  # that branch carries 18.8.4 against the pin's 18.10.0 (checked
                  # 2026-10-13). See the change `current-omp-release`, design D2.
                  ompPackage = (agentPkgsFor "x86_64-linux").omp;
                };
                users.dan = import ./home/dan/thiniel.nix;
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  ./modules/home-manager/persistence
                  ./modules/home-manager/ssh/options.nix
                ];
              };
            }
          ];
        };
        cupix001 = nixpkgs.lib.nixosSystem {
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
            ./hosts/cupix001
            inputs.private.nixosModules.cupix001
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
                    system = "x86_64-linux";
                  };
                };
                users.dan = import ./home/dan/cupix001.nix;
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                  ./modules/home-manager/persistence
                ];
              };
            }
          ];
        };
        adlerkopf = nixpkgs.lib.nixosSystem {
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
            ./hosts/adlerkopf
            inputs.private.nixosModules.adlerkopf
            disko.nixosModules.disko
            lanzaboote.nixosModules.lanzaboote
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
                users.dan = import ./home/dan/adlerkopf.nix;
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
                inputs.givn.overlays.default
                (import ./overlays)
              ];
              nixpkgs.config.allowUnfree = true;
            }
            mac-app-util.darwinModules.default
            nix-homebrew.darwinModules.nix-homebrew
            ./hosts/J6G6Y9JK7L
            stylix-unstable.darwinModules.stylix
            home-manager-unstable.darwinModules.home-manager
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
                  # The agent's package, from its own pin, so both devices carry
                  # the same agent and the same asserted floor. See the change
                  # `current-omp-release`, design D2.
                  ompPackage = (agentPkgsFor "aarch64-darwin").omp;
                };
                users."daniel.kressner" = import ./home/dan/J6G6Y9JK7L.nix;
                sharedModules = [
                  mac-app-util.homeManagerModules.default
                  sops-nix.homeManagerModules.sops
                  ./modules/home-manager/persistence/options.nix
                  ./modules/home-manager/ssh/options.nix
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
                    pkgs.python3Packages.types-requests
                    pkgs.python3Packages.pytest
                    pkgs.python3Packages.mypy
                    pkgs.python3Packages.secretstorage
                    pkgs.ruff
                    # Phase 2: OpenAPI client generation
                    pkgs.openapi-python-client
                    pkgs.python3Packages.httpx
                    pkgs.python3Packages.attrs
                    pkgs.python3Packages.python-dateutil
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

      # ── Packages ─────────────────────────────────────────────────────────
      packages = builtins.listToAttrs (
        map
          (system: {
            name = system;
            value = {
              mcp-nixos = mcp-nixos.packages.${system}.default;
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
            value = nixpkgs.legacyPackages.${system}.nixfmt;
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

              # The public defaults must stay non-operational: with the stub
              # `private` input (no override) every host's declared network
              # values must be documentation-range placeholders or empty.
              private-data-defaults =
                let
                  lib' = nixpkgs.lib;
                  adlerkopf = self.nixosConfigurations.adlerkopf.config.networking.adlerkopf;
                  cupix001 = self.nixosConfigurations.cupix001.config.networking.cupix001;
                  offending = lib'.flatten [
                    (lib'.optional (adlerkopf.lanIPv4 != "192.0.2.10") "adlerkopf.lanIPv4")
                    (lib'.optional (adlerkopf.gateway4 != "192.0.2.1") "adlerkopf.gateway4")
                    (lib'.optional (adlerkopf.wgSubnet != "10.0.0.0/24") "adlerkopf.wgSubnet")
                    (lib'.optional (adlerkopf.wgServerIPv4 != "10.0.0.1") "adlerkopf.wgServerIPv4")
                    (lib'.optional (cupix001.publicIPv4 != "") "cupix001.publicIPv4")
                    (lib'.optional (cupix001.gateway4 != "") "cupix001.gateway4")
                    (lib'.optional (cupix001.wgTunnelIPv4 != "") "cupix001.wgTunnelIPv4")
                  ];
                  offendingText = builtins.concatStringsSep "\n" offending;
                in
                pkgs.runCommand "private-data-defaults"
                  {
                    inherit offendingText;
                    passAsFile = [ "offendingText" ];
                  }
                  (
                    if offending == [ ] then
                      ''
                        echo "host network defaults are documentation-range placeholders or empty"
                        touch $out
                      ''
                    else
                      ''
                        echo "host network defaults carry operational values:"
                        cat $offendingTextPath
                        exit 1
                      ''
                  );

              # The recorded content must carry no operational value, no
              # per-host private-value file and no unencrypted secret.
              private-data-hygiene =
                pkgs.runCommand "private-data-hygiene"
                  {
                    src = self;
                    nativeBuildInputs = [ pkgs.python3 ];
                    guard = ./scripts/private_data_hygiene.py;
                  }
                  ''
                    # 1. the recorded tree must be clean
                    python3 $guard --tree $src
                    # 2. the value rule must reject an in-class value that is
                    #    not any literal currently in the tree
                    mkdir -p bad/value bad/file bad/secret
                    # Assembled at run time so this file records no literal.
                    printf 'lanIPv4 = "192.168.%s.77";\n' 168 > bad/value/x.nix
                    printf '_: { }\n' > bad/file/private.nix
                    printf 'placeholder: initial-setup\n' > bad/secret/secrets.yaml
                    for case in value file secret; do
                      if python3 $guard --tree bad/$case; then
                        echo "guard accepted the $case fixture" >&2
                        exit 1
                      fi
                    done
                    touch $out
                  '';

              # The agent's secret-access guard must refuse decryption work and
              # leave ordinary repository work alone. The hook is a plugin the
              # agent loads at run time; this driver supplies the runtime
              # stand-in and asserts the verdict for each recorded tool call, so
              # the contract is checked without a model, a session or a network.
              unit-agent-secret-guard =
                let
                  agentPkgs = agentPkgsFor system;
                in
                pkgs.runCommand "unit-agent-secret-guard"
                  {
                    nativeBuildInputs = [ agentPkgs.bun ];
                    driver = ./tests/unit/agent-secret-guard.mjs;
                    hook = ./.omp/hooks/pre/secret-access-guard.js;
                  }
                  ''
                    # the agent's runtime wants a writable home; the sandbox has
                    # no real one for the build user
                    export HOME="$TMPDIR"
                    bun "$driver" "$hook"
                    touch $out
                  '';

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
                    nativeBuildInputs = [ pkgs.nixfmt ];
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
                integrationTests = import ./tests/integration/default.nix {
                  inherit pkgs sops-nix home-manager-unstable;
                  # The booted check carries the agent from its own pin, so the
                  # guest proves the version floor the devices assert.
                  ompPackage = (agentPkgsFor system).omp;
                };
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
