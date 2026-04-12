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
    ];
  };
}
