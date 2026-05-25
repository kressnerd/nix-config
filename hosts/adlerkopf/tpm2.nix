_: {
  # Required for TPM2-backed unlock via systemd-cryptsetup in initrd
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    crypttabExtraOpts = [ "tpm2-device=auto" ];
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
