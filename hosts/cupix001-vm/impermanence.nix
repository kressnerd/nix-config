{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/headscale"
      "/var/lib/private" # systemd DynamicUser
      "/var/lib/acme"
      "/etc/nixos"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  # Ensure /persist structure exists
  systemd.tmpfiles.rules = [
    "d /persist 0755 root root -"
    "d /persist/home 0755 root root -"
    "d /persist/var 0755 root root -"
    "d /persist/var/lib 0755 root root -"
    "d /persist/etc 0755 root root -"
  ];
}
