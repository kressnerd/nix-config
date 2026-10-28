# tests/integration/managed-file-displacement-test.nix
# Integration test: a booted device applies its configuration although a program
# on the device rewrote a file the home profile manages, on the first rewrite and
# on a later one.
#
# The displacement command is the value the device's configuration declares,
# passed in from the flake, so the check proves the declared setting rather than a
# test-local one. With `null` declared (the pre-change state) the guest's Home
# Manager activation aborts on the foreign file.
#
# Run: nix build .#checks.<linux-system>.integration-managed-file-displacement
{
  pkgs,
  home-manager,
  backupCommand,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "managed-file-displacement";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      users.users.test = {
        isNormalUser = true;
        password = "testpass";
      };

      # What a program on the device produced: it rewrote a managed file, and one
      # earlier rewrite had already been displaced, so the first free number is 2.
      # The seed runs inside the system activation, which stage 2 executes before
      # systemd starts, so it always precedes the home profile's own activation.
      system.activationScripts.seedRewrittenManagedFile = {
        deps = [ "users" ];
        text = ''
          # The whole path is created for the test user: a root-owned
          # /home/test/.config would make the home profile's own activation fail
          # on permissions instead of on the file it is learning to displace.
          install -d -o test -g users /home/test/.config /home/test/.config/example
          printf 'written by a program\n' > /home/test/.config/example/settings.conf
          printf 'written even earlier\n' > /home/test/.config/example/settings.conf.1
          chown test:users /home/test/.config/example /home/test/.config/example/settings.conf /home/test/.config/example/settings.conf.1
        '';
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        inherit backupCommand;

        users.test = {
          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "26.05";
          };

          home.file.".config/example/settings.conf".text = "rendered by the configuration\n";
        };
      };

      # The home profile the guest loads and its package set must come from the
      # same release: the condition behind Home Manager's release check.
      assertions = [
        {
          assertion = config.home-manager.users.test.home.version.release == pkgs.lib.trivial.release;
          message = "the test profile's Home Manager release must equal the guest package set's release (change managed-file-displacement)";
        }
      ];
    };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The configuration applied: its rendered file is in place.
    machine.succeed("test -L /home/test/.config/example/settings.conf")
    rendered = machine.succeed("cat /home/test/.config/example/settings.conf")
    assert "rendered by the configuration" in rendered, rendered

    # The earlier displaced copy is untouched, and this rewrite landed beside it.
    earlier = machine.succeed("cat /home/test/.config/example/settings.conf.1")
    assert "written even earlier" in earlier, earlier
    current = machine.succeed("cat /home/test/.config/example/settings.conf.2")
    assert "written by a program" in current, current
  '';
}
