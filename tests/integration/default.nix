# tests/integration/default.nix
# Aggregates integration tests for the flake checks output
# Each test is a pkgs.testers.runNixOSTest derivation (Linux-only)
{
  pkgs,
  unstablePkgs,
  backupCommand,
  home-manager-unstable,
  sops-nix,
  ompPackage,
  opencodePackage ? null,
  rustToolchain,
  cargoLlvmCov,
  ...
}:
{
  integration-vm-minimal-ssh = import ./nixos-vm-minimal-test.nix { inherit pkgs; };
  integration-adlerkopf = import ./adlerkopf-test.nix { inherit pkgs; };
  # These two checks load the devices' Home Manager modules, so their guest
  # package set comes from the same pin those modules follow (nixpkgs-unstable):
  # Home Manager refuses a release pairing it does not match, and the pairing is
  # what the two devices themselves run. See the change
  # `quiet-configuration-evaluation`, design D3.
  integration-ssh-identity-selection = import ./ssh-identity-selection-test.nix {
    pkgs = unstablePkgs;
    inherit sops-nix;
    home-manager = home-manager-unstable;
  };
  integration-private-data-separation = import ./private-data-separation-test.nix {
    inherit pkgs;
  };
  integration-github-fetch-credential = import ./github-fetch-credential-test.nix {
    inherit pkgs sops-nix;
  };
  integration-agent-tooling = import ./agent-tooling-test.nix {
    pkgs = unstablePkgs;
    inherit ompPackage opencodePackage;
    home-manager = home-manager-unstable;
  };
  integration-managed-file-displacement = import ./managed-file-displacement-test.nix {
    pkgs = unstablePkgs;
    inherit backupCommand;
    home-manager = home-manager-unstable;
  };
  integration-rust-toolchain = import ./rust-toolchain-test.nix {
    pkgs = unstablePkgs;
    home-manager = home-manager-unstable;
    inherit rustToolchain cargoLlvmCov;
  };
  integration-infrastructure-tooling = import ./infrastructure-tooling-test.nix {
    pkgs = unstablePkgs;
    home-manager = home-manager-unstable;
  };
}
