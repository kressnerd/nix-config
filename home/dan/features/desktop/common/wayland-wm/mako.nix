{config, ...}: {
  services.mako = {
    enable = true;
    settings = {
      font = "${config.fontProfiles.regular.name} ${toString config.fontProfiles.regular.size}";
      padding = "10,20";
      anchor = "top-center";
      width = 400;
      height = 150;
      border-size = 2;
      default-timeout = 12000;
      border-radius = 10;
      layer = "overlay";
      max-history = 50;
    };
  };
}
