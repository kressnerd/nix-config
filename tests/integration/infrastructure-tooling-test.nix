# tests/integration/infrastructure-tooling-test.nix
# Integration test: a booted device that provides the infrastructure authoring
# tools runs OpenTofu and the GitHub CLI from the ordinary user's profile.
#
# Run: nix build .#checks.<linux-system>.integration-infrastructure-tooling
{
  pkgs,
  home-manager,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "infrastructure-tooling";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      users.users.test = {
        isNormalUser = true;
        password = "testpass";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.test = {
          imports = [ ../../home/dan/features/cli/infrastructure-tooling.nix ];

          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "25.11";
          };
        };
      };

      # The Home Manager module and the guest package set must come from the
      # same release, or Home Manager refuses the pairing.
      assertions = [
        {
          assertion = config.home-manager.users.test.home.version.release == pkgs.lib.trivial.release;
          message = "the test profile's Home Manager release must equal the guest package set's release (change infrastructure-authoring-tooling)";
        }
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The tools are Home Manager packages of the test user; resolve them from
    # that user's profile rather than root's PATH.
    profile = "/etc/profiles/per-user/test/bin"
    as_test = f"sudo -u test env HOME=/home/test PATH={profile}"

    tofu = machine.succeed(f"{as_test} tofu version")
    assert "OpenTofu" in tofu, tofu

    gh = machine.succeed(f"{as_test} gh --version")
    assert "gh version" in gh, gh
  '';
}
