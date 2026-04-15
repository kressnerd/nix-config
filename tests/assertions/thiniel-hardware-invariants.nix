# tests/assertions/thiniel-hardware-invariants.nix
# Thiniel-specific hardware assertions — enforced at evaluation time via nix flake check
# Covers: Bluetooth, fwupd, WWAN, battery thresholds, and other hardware concerns
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.hardware.bluetooth.enable;
        message = "thiniel: Bluetooth must be enabled";
      }
      {
        assertion = config.services.fwupd.enable;
        message = "thiniel: fwupd firmware update service must be enabled";
      }
      {
        assertion = (config.services.auto-cpufreq.settings.battery.enable_thresholds or "") == "true";
        message = "thiniel: auto-cpufreq battery charge thresholds must be enabled";
      }
      {
        assertion = !config.services.tlp.enable;
        message = "thiniel: TLP must not be enabled (conflicts with auto-cpufreq)";
      }
      {
        assertion = config.networking.modemmanager.enable;
        message = "thiniel: ModemManager must be enabled for WWAN modem";
      }
      {
        assertion = builtins.any (
          p: (p.pname or p.name or "") == "NetworkManager-openvpn"
        ) config.networking.networkmanager.plugins;
        message = "thiniel: NetworkManager OpenVPN plugin must be installed";
      }
      {
        assertion = builtins.match ".*bInterfaceClass.*03.*" config.services.udev.extraRules != null;
        message = "thiniel: udev must disable USB autosuspend for HID input devices (bInterfaceClass==03)";
      }
      {
        assertion = builtins.match ".*power/control.*" config.powerManagement.powertop.postStart != null;
        message = "thiniel: powertop postStart must re-apply USB HID autosuspend disable after auto-tune";
      }
      {
        assertion = config.powerManagement.powertop.enable;
        message = "thiniel: powertop auto-tune must remain enabled for power savings";
      }
    ];
  };
}
