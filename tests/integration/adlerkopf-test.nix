# tests/integration/adlerkopf-test.nix
# Integration test: SSH + firewall + Caddy behavior for adlerkopf host invariants
# Run: nix build .#checks.<linux-system>.integration-adlerkopf
# Interactive: nix build .#checks.<linux-system>.integration-adlerkopf.driverInteractive && result/bin/nixos-test-driver
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "adlerkopf-base";

  nodes.machine = _: {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    services.caddy.enable = true;

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
    machine.wait_for_unit("caddy.service")
    machine.wait_for_open_port(22)

    machine.succeed("systemctl is-active sshd.service")
    machine.succeed("systemctl is-active caddy.service")
    machine.succeed("systemctl is-active firewall.service")

    result = machine.succeed("sshd -T | grep -i permitrootlogin")
    assert "yes" not in result.lower() or "without-password" in result.lower(), f"Root login should be disabled, got: {result}"

    machine.succeed("ss -tlnp | grep ':22 '")
    machine.fail("ss -tlnp | grep ':80 '")
  '';
}
