{
  description = "Stub for the overridable `private` input: no-op host modules so the public flake evaluates without the real private repository.";

  outputs = _: {
    nixosModules = {
      # The public fallback must stay non-operational: it supplies no value and
      # asserts that each host's declared network values are documentation-range
      # placeholders or empty. A deploy supplies the real values by overriding
      # this input with the private flake.
      adlerkopf =
        { config, lib, ... }:
        let
          cfg = config.networking.adlerkopf;
        in
        {
          assertions = [
            {
              assertion = cfg.lanIPv4 == "" || lib.hasPrefix "192.0.2." cfg.lanIPv4;
              message = "private-stub: networking.adlerkopf.lanIPv4 must be a documentation-range placeholder (192.0.2.0/24) or empty when no private source supplies values, got '${cfg.lanIPv4}'";
            }
            {
              assertion = cfg.gateway4 == "" || lib.hasPrefix "192.0.2." cfg.gateway4;
              message = "private-stub: networking.adlerkopf.gateway4 must be a documentation-range placeholder (192.0.2.0/24) or empty when no private source supplies values, got '${cfg.gateway4}'";
            }
            {
              assertion = cfg.wgSubnet == "" || cfg.wgSubnet == "10.0.0.0/24";
              message = "private-stub: networking.adlerkopf.wgSubnet must be the generic placeholder 10.0.0.0/24 or empty when no private source supplies values, got '${cfg.wgSubnet}'";
            }
            {
              assertion = cfg.wgServerIPv4 == "" || cfg.wgServerIPv4 == "10.0.0.1";
              message = "private-stub: networking.adlerkopf.wgServerIPv4 must be the generic placeholder 10.0.0.1 or empty when no private source supplies values, got '${cfg.wgServerIPv4}'";
            }
          ];
        };

      cupix001 =
        { config, ... }:
        let
          cfg = config.networking.cupix001;
          empties = {
            inherit (cfg)
              publicIPv4
              publicIPv6
              gateway4
              gateway6
              wgTunnelIPv4
              wgPeerTunnelIPv4
              ;
          };
          offending = builtins.filter (n: empties.${n} != "") (builtins.attrNames empties);
        in
        {
          assertions = [
            {
              assertion = offending == [ ] && cfg.dns == [ ];
              message = "private-stub: networking.cupix001.* must be empty when no private source supplies values, got values for ${builtins.toString offending} and ${builtins.toString (builtins.length cfg.dns)} DNS resolver(s)";
            }
          ];
        };
    };
  };
}
