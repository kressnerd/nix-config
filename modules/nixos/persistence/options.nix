# SPDX-FileCopyrightText: 2026 Daniel Kressner
#
# SPDX-License-Identifier: MPL-2.0

{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mySystem.persistence = {
    enable = mkEnableOption "NixOS impermanence persistence";
    root = mkOption {
      type = types.str;
      default = "/persist/system";
      description = "Root mount point for NixOS system persistence bind mounts.";
    };
  };
}
