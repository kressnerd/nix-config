# tests/integration/agent-tooling-test.nix
# Integration test: a booted device carries its coding agents at or above their
# accepted version floors, installs the guarded agent's secret-access guard where
# the agent discovers hooks, and starts each agent while holding none of its
# servers' key material.
#
# The repository's own OpenCode package is passed only where the overlay supports
# the system (x86_64-linux, aarch64-darwin); where it is absent the check proves
# the guarded agent's half alone.
#
# Run: nix build .#checks.<linux-system>.integration-agent-tooling
# Interactive: nix build .#checks.<linux-system>.integration-agent-tooling.driverInteractive && result/bin/nixos-test-driver
{
  pkgs,
  home-manager,
  ompPackage,
  opencodePackage ? null,
  ...
}:
let
  inherit (pkgs) lib;

  # The agents are Home Manager packages of the test user, so the test driver
  # (root, system PATH) cannot resolve them by name. The store path of the package
  # the device declares is PATH-independent and proves the declared package runs.
  # Asserting that a login shell resolves them would test Home Manager's shell
  # integration rather than the agents.
  agentBin = "${ompPackage}/bin/omp";
  floor = "18.10";

  withOpencode = opencodePackage != null;
  opencodeBin = if withOpencode then "${opencodePackage}/bin/opencode" else "";
in
pkgs.testers.runNixOSTest {
  name = "agent-tooling";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ home-manager.nixosModules.home-manager ];

      users.users.test = {
        isNormalUser = true;
        password = "testpass";
      };

      # The device declares its agents and nothing else: no sops secrets, so neither
      # server's key command can succeed here.
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit ompPackage;
        }
        // lib.optionalAttrs withOpencode { inherit opencodePackage; };
        users.test = {
          imports = [
            ../../home/dan/features/development/omp.nix
          ]
          ++ lib.optional withOpencode ../../home/dan/features/development/opencode.nix;

          home = {
            username = "test";
            homeDirectory = "/home/test";
            stateVersion = "25.11";
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
    import re

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The guarded agent the device declares starts and reports its version.
    reported = machine.succeed("sudo -u test env HOME=/home/test ${agentBin} --version").strip()
    match = re.search(r"(\d+)\.(\d+)", reported)
    assert match, f"no version in {reported!r}"
    major, minor = int(match.group(1)), int(match.group(2))
    assert (major, minor) >= (18, 10), f"agent reports {reported!r}, below the floor ${floor}"

    # The guard lands where the agent discovers hooks: a regular file, because
    # the agent's hook discovery skips symlinks.
    guard = "/home/test/.omp/agent/hooks/pre/secret-access-guard.js"
    machine.succeed(f"test -f {guard}")
    machine.fail(f"test -L {guard}")

    # The two shared servers are declared, and neither key exists on this device:
    # a key-less device must still start the agent.
    declared = machine.succeed("cat /home/test/.omp/agent/mcp.json")
    assert "context7" in declared and "kagi-search" in declared, declared
    machine.fail("test -e /home/test/.config/sops-nix/secrets/context7/api-key")
    machine.fail("test -e /home/test/.config/sops-nix/secrets/kagi/api-key")
  ''
  + lib.optionalString withOpencode ''
    # The second coding agent the device carries starts and reports its version.
    # Three components, because 2.0.22 and 2.0.28 share major and minor: a
    # two-component comparison would pass a build below the floor.
    opencode_version = machine.succeed("sudo -u test env HOME=/home/test ${opencodeBin} --version").strip()
    opencode_match = re.search(r"(\d+)\.(\d+)\.(\d+)", opencode_version)
    assert opencode_match, f"no version in {opencode_version!r}"
    opencode_triple = tuple(int(part) for part in opencode_match.groups())
    assert opencode_triple >= (2, 0, 28), f"OpenCode reports {opencode_version!r}, below the floor 2.0.28"
  '';
}
