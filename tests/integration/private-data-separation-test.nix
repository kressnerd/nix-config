# tests/integration/private-data-separation-test.nix
# Integration test: a host whose network values are supplied from outside the
# repository boots with exactly those values, rather than with the public
# documentation-range placeholders.
# Run: nix build .#checks.<linux-system>.integration-private-data-separation
{
  pkgs,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "private-data-separation";

  nodes.machine = {
    imports = [
      ../../hosts/adlerkopf/options.nix
      ../../hosts/adlerkopf/networking.nix
    ];

    # A stand-in for the private flake input: the values reach the host from
    # outside this repository. Documentation-range values are used so the test
    # itself records nothing operational.
    networking.adlerkopf = {
      interfaceName = "eth0";
      lanIPv4 = "198.51.100.10";
      lanPrefix = 24;
      gateway4 = "198.51.100.1";
      dns = [ "1.1.1.1" ];
      wgSubnet = "10.0.0.0/24";
      wgServerIPv4 = "10.0.0.1";
      wgListenPort = 51820;
    };

    system.stateVersion = "26.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("systemd-networkd.service")

    # The supplied address, not the placeholder, is what the interface carries.
    machine.succeed("ip -4 addr show | grep -F '198.51.100.10'")
    machine.fail("ip -4 addr show | grep -F '192.0.2.10'")
  '';
}
