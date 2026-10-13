# tests/integration/ssh-identity-selection-test.nix
# Integration test: a booted device resolves private-repository access to the
# identity it declares, and declares no identity whose material it does not hold.
# Run: nix build .#checks.<linux-system>.integration-ssh-identity-selection
# Interactive: nix build .#checks.<linux-system>.integration-ssh-identity-selection.driverInteractive && result/bin/nixos-test-driver
{
  pkgs,
  home-manager,
  sops-nix,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "ssh-identity-selection";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      users.users.test = {
        isNormalUser = true;
        password = "testpass";
      };

      # The device declares the identity it holds. It declares no work identity
      # secret material, so no work connection entry may be rendered.
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules = [
          sops-nix.homeManagerModules.sops
          ../../modules/home-manager/ssh/options.nix
          ../../modules/home-manager/persistence/options.nix
        ];
        users.test = {
          imports = [ ../../home/dan/features/cli/ssh.nix ];

          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "25.11";
          };

          myHome.ssh = {
            personalIdentityFile = "~/.ssh/id_ed25519";
            includedConfigs = [ ];
          };
        };
      };

      # The Home Manager modules this device loads and the package set they run
      # against must come from the same release. This asserts the condition behind
      # Home Manager's release check, without matching its warning text.
      assertions = [
        {
          assertion = config.home-manager.users.test.home.version.release == pkgs.lib.trivial.release;
          message = "the test profile's Home Manager release must equal the guest package set's release (change quiet-configuration-evaluation)";
        }
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The declared identity is what the private-repository connection resolves to.
    rendered = machine.succeed("sudo -u test ssh -G github-personal")
    assert "identityfile ~/.ssh/id_ed25519" in rendered, rendered
    assert "identitiesonly yes" in rendered, rendered

    # No identity whose material this device does not hold may be declared, and
    # no manually maintained configuration file may be included.
    config = machine.succeed("cat /home/test/.ssh/config")
    assert "IdentityFile ~/.ssh/id_ed25519" in config, config
    for foreign in ("github-company", "github-client001", "bitbucket-client002", "config.d/"):
        assert foreign not in config, f"{foreign} must not be declared:\n{config}"
  '';
}
