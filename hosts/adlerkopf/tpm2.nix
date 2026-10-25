_: {
  boot.initrd.luks.devices.cryptroot = {
    crypttabExtraOpts = [ "tpm2-device=auto" ];
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
