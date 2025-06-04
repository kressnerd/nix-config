{
  config,
  ...
}: {
  hardware.bluetooth = {
    enable = true;
  };

  # Wireless secrets stored through sops
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.networkmanager.enable = true;
#  networking.wireless = {
#    enable = true;
#    fallbackToWPA2 = false;
    # Declarative
#    secretsFile = config.sops.secrets.wireless.path;
#    networks = {
#      "CAT_HOUSE" = {
#        pskRaw = "ext:cat_house";
#      };
#      "Marcos_2.4Ghz" = {
#        pskRaw = "ext:marcos_24";
#      };
#      "Marcos_5Ghz" = {
#        pskRaw = "ext:marcos_50";
#      };
#      "Misterio" = {
#        pskRaw = "ext:misterio";
#      };
#      "VIVOFIBRA-FC41-5G" = {
#        pskRaw = "ext:marcos_santos_5g";
#      };
#      };
#    };

    # Imperative
#    allowAuxiliaryImperativeNetworks = true;
#    userControlled = {
#      enable = true;
#      group = "network";
#    };
#    extraConfig = ''
#      update_config=1
#    '';
#  };

  # Ensure group exists
#  users.groups.network = {};

#  systemd.services.wpa_supplicant.preStart = "touch /etc/wpa_supplicant.conf";
}
