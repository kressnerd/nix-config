# SPDX-FileCopyrightText: 2026 Daniel Kressner
#
# SPDX-License-Identifier: MPL-2.0

{ config, lib, ... }:
let
  cfg = config.myHome.persistence;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    home.persistence.${cfg.root} = {
      directories = [
        ".cache/mesa_shader_cache"
        ".cache/mesa_shader_cache_db"
        "dev"
        "Projects"
        ".config/sops/age"
        ".config/netcup-scp"
        ".local/share/netcup-scp"
        ".local/share/fish"
        ".local/share/opencode"
        ".cache/opencode"
        ".omp"
        # Maki keeps config, auth, sessions, logs and its cache under XDG paths;
        # the root wipe would otherwise discard every session on thiniel.
        ".config/maki"
        ".local/share/maki"
        ".local/state/maki"
        ".local/logs/maki"
        ".cache/maki"
      ];
      files = [
        ".bash_history"
      ];
    };
  };
}
