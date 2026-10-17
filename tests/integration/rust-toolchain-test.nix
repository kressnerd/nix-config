# tests/integration/rust-toolchain-test.nix
# Integration test: a booted device that declares the Rust build toolchain
# creates, builds, runs and lints a dependency-free Rust project.
#
# Run: nix build .#checks.<linux-system>.integration-rust-toolchain
# Interactive: nix build .#checks.<linux-system>.integration-rust-toolchain.driverInteractive && result/bin/nixos-test-driver
{
  pkgs,
  home-manager,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "rust-toolchain";

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
        sharedModules = [
          # The module reads myHome.persistence.enable; the option default is
          # off, so the guest does not need the impermanence module.
          ../../modules/home-manager/persistence/options.nix
        ];
        users.test = {
          imports = [ ../../home/dan/features/development/rust.nix ];

          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "25.11";
          };
        };
      };

      # The Home Manager modules this device loads and the package set they run
      # against must come from the same release: the condition behind Home
      # Manager's release check.
      assertions = [
        {
          assertion = config.home-manager.users.test.home.version.release == pkgs.lib.trivial.release;
          message = "the test profile's Home Manager release must equal the guest package set's release (change rust-build-toolchain)";
        }
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The toolchain is a Home Manager package of the test user; resolve it from
    # that user's profile rather than root's PATH.
    profile = "/etc/profiles/per-user/test/bin"
    as_test = f"sudo -u test env HOME=/home/test PATH={profile}"

    machine.succeed(f"{as_test} rustc --version")
    machine.succeed(f"{as_test} cargo --version")
    machine.succeed(f"{as_test} gcc --version")
    machine.succeed(f"{as_test} pkg-config --version")

    # A dependency-free project: the build must not need the network.
    machine.succeed(f"{as_test} cargo new --vcs none --offline /home/test/hello")
    machine.succeed(f"{as_test} cargo build --offline --manifest-path /home/test/hello/Cargo.toml")
    produced = machine.succeed(f"{as_test} /home/test/hello/target/debug/hello")
    assert "Hello, world!" in produced, produced

    machine.succeed(f"{as_test} cargo clippy --offline --manifest-path /home/test/hello/Cargo.toml")
  '';
}
