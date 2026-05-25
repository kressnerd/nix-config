{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.networking.hostName == "adlerkopf") {
    assertions = [
      {
        assertion = config.networking.hostName == "adlerkopf";
        message = "adlerkopf: hostName must be adlerkopf";
      }
      {
        assertion = config.networking.firewall.enable;
        message = "adlerkopf: firewall must be enabled";
      }
      {
        assertion = !config.networking.networkmanager.enable;
        message = "adlerkopf: NetworkManager must be disabled (server host)";
      }
    ];
  };
}
