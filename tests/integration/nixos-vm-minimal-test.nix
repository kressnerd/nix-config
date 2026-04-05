# tests/integration/nixos-vm-minimal-test.nix
# Integration test: SSH + firewall behavior in a minimal NixOS VM
# Run: nix build .#checks.<linux-system>.integration-vm-minimal-ssh
# Interactive: nix build .#checks.<linux-system>.integration-vm-minimal-ssh.driverInteractive && result/bin/nixos-test-driver
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "vm-minimal-ssh-firewall";

  nodes.machine = _: {
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
      allowedTCPPorts = [ 22 ];
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

    # Verify SSH root login is disabled (query running config, not static file)
    result = machine.succeed("sshd -T | grep -i permitrootlogin")
    assert "yes" not in result.lower() or "without-password" in result.lower(), f"Root login should be disabled, got: {result}"

    # Verify port 22 is listening
    machine.succeed("ss -tlnp | grep ':22 '")

    # Verify port 80 is NOT listening
    machine.fail("ss -tlnp | grep ':80 '")

    # Verify testuser exists
    machine.succeed("id testuser")
  '';
}
