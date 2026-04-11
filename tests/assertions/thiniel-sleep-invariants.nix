# tests/assertions/thiniel-sleep-invariants.nix
# Thiniel-specific sleep/hibernate assertions — enforced at evaluation time via nix flake check
# Protects against OPAL SED FDE firmware bug: encryption key is lost when RAM is offloaded
# (suspend-to-RAM, suspend-to-disk, hybrid sleep all brick the system until cold reboot)
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      # logind — lid switch must not suspend
      {
        assertion = (config.services.logind.settings.Login.HandleLidSwitch or "suspend") == "ignore";
        message = "Thiniel invariant violated: HandleLidSwitch must be ignore — OPAL SED loses encryption key on suspend";
      }
      {
        assertion = (config.services.logind.settings.Login.HandleLidSwitchDocked or "suspend") == "ignore";
        message = "Thiniel invariant violated: HandleLidSwitchDocked must be ignore — OPAL SED loses encryption key on suspend";
      }
      {
        assertion =
          (config.services.logind.settings.Login.HandleLidSwitchExternalPower or "suspend") == "ignore";
        message = "Thiniel invariant violated: HandleLidSwitchExternalPower must be ignore — OPAL SED loses encryption key on suspend";
      }
      # systemd.sleep — block all sleep states
      {
        assertion = (config.systemd.sleep.settings.Sleep.AllowSuspend or "yes") == "no";
        message = "Thiniel invariant violated: AllowSuspend must be no — OPAL SED loses encryption key on suspend";
      }
      {
        assertion = (config.systemd.sleep.settings.Sleep.AllowHibernation or "yes") == "no";
        message = "Thiniel invariant violated: AllowHibernation must be no — OPAL SED loses encryption key on hibernate";
      }
      {
        assertion = (config.systemd.sleep.settings.Sleep.AllowHybridSleep or "yes") == "no";
        message = "Thiniel invariant violated: AllowHybridSleep must be no — OPAL SED loses encryption key on hybrid sleep";
      }
      {
        assertion = (config.systemd.sleep.settings.Sleep.AllowSuspendThenHibernate or "yes") == "no";
        message = "Thiniel invariant violated: AllowSuspendThenHibernate must be no — OPAL SED loses encryption key";
      }
    ];
  };
}
