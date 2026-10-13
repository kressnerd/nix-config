# tests/integration/agent-tooling-test.nix
# Integration test: a booted device carries the coding agent at or above the
# accepted version floor, installs its secret-access guard where the agent
# discovers hooks, and starts the agent while holding none of its servers' key
# material.
#
# Run: nix build .#checks.<linux-system>.integration-agent-tooling
# Interactive: nix build .#checks.<linux-system>.integration-agent-tooling.driverInteractive && result/bin/nixos-test-driver
{
  pkgs,
  home-manager,
  ompPackage,
  ...
}:
let
  # The agent is a Home Manager package of the test user, so the test driver
  # (root, system PATH) cannot resolve it by name. The store path of the package
  # the device declares is PATH-independent and proves the declared package
  # runs. Asserting that a login shell resolves `omp` would test Home Manager's
  # shell integration rather than the agent.
  agentBin = "${ompPackage}/bin/omp";
  floor = "18.10";
in
pkgs.testers.runNixOSTest {
  name = "agent-tooling";

  nodes.machine = {
    imports = [ home-manager.nixosModules.home-manager ];

    users.users.test = {
      isNormalUser = true;
      password = "testpass";
    };

    # The device declares its agent and nothing else: no sops secrets, so neither
    # server's key command can succeed here.
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit ompPackage; };
      users.test = {
        imports = [ ../../home/dan/features/development/omp.nix ];

        home = {
          username = "test";
          homeDirectory = "/home/test";
          stateVersion = "25.11";
        };
      };
    };
  };

  testScript = ''
    import re

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("home-manager-test.service")

    # The agent the device declares starts and reports its version.
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
  '';
}
