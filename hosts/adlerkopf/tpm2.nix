_: {
  # Required for TPM2-backed unlock via systemd-cryptsetup in initrd
  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices.cryptroot = {
    crypttabExtraOpts = [ "tpm2-device=auto" ];
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
