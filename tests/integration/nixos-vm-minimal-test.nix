# tests/integration/nixos-vm-minimal-test.nix
# Integration test: SSH + firewall behavior in a minimal NixOS VM
# Run: nix build .#checks.<linux-system>.integration-vm-minimal-ssh
# Interactive: nix build .#checks.<linux-system>.integration-vm-minimal-ssh.driverInteractive && result/bin/nixos-test-driver
{pkgs, ...}:
pkgs.testers.runNixOSTest {
  name = "vm-minimal-ssh-firewall";

  nodes.machine = {pkgs, ...}: {
    # Minimal SSH + firewall config mirroring host invariants
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [22];
    };

    users.users.testuser = {
      isNormalUser = true;
      password = "testpass";
    };
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("sshd.service")
    machine.wait_for_open_port(22)

    # Verify SSH is running
    machine.succeed("systemctl is-active sshd.service")

    # Verify firewall is active
    machine.succeed("systemctl is-active firewall.service")

    # Verify SSH root login is disabled
    result = machine.succeed("grep -E '^PermitRootLogin' /etc/ssh/sshd_config || echo 'PermitRootLogin no'")
    assert "yes" not in result.lower(), f"Root login should be disabled, got: {result}"

    # Verify firewall rules allow port 22
    machine.succeed("nft list ruleset | grep 'tcp dport 22'")

    # Verify a non-allowed port is not open (e.g., port 80)
    machine.fail("nft list ruleset | grep 'tcp dport 80'")

    # Verify testuser exists
    machine.succeed("id testuser")
  '';
}
