# SPDX-FileCopyrightText: 2026 Daniel Kressner
#
# SPDX-License-Identifier: MPL-2.0

{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.myHome.ssh = {
    personalIdentityFile = mkOption {
      type = types.str;
      description = ''
        Private key file of this host's personal identity, as it is used for
        private repositories. Declared per host: a host reaches private
        repositories with the identity material it holds.
      '';
    };

    includedConfigs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Manually maintained ssh_config files this host includes before the
        managed connection entries. Empty for a host that keeps none.
      '';
    };
  };
}
