{
  config,
  pkgs,
  lib,
  ...
}: {
  # System hardening
  security = {
    # Lockdown kernel modules
    lockKernelModules = true;

    # AppArmor profiles
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # Audit daemon for security monitoring
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-a exit,always -F arch=b64 -S execve"
    ];
  };

  # Disable unnecessary services
  services.avahi.enable = false;
  services.printing.enable = false;

  # No GUI
  services.xserver.enable = false;

  # Strict umask
  security.loginDefs.settings = {
    UMASK = "077";
  };

  # PAM hardening
  security.pam.services = {
    su.requireWheel = true;
    su-l.requireWheel = true;
  };
}
