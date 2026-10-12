{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
let
  # Sops prohibition for omp, mirroring the sops rules of the repository's
  # `opencode.json`: no `sops`, `ssh-to-age`, or `age -d`/`--decrypt`
  # invocation, and no read of the decrypted material (`/run/secrets`,
  # `*/sops/age/*`, `*/var/lib/sops-nix/*`) through `read`, `grep`, `bash`, or
  # `eval`. This is the same file the repository installs as its project hook
  # (`.omp/hooks/pre/secret-access-guard.js`); the agent-directory copy makes
  # omp discover it ambiently in every session, from any working directory.
  sopsGuard = ../../../../.omp/hooks/pre/secret-access-guard.js;

  # User-level MCP servers for omp, matching the two servers declared for
  # OpenCode in `opencode.nix` (context7, kagi-search). omp does not pick them up
  # from the OpenCode user config: that foreign source is opt-in via
  # `enabledProviders`, and its OpenCode reader expects the v1 `mcp.<name>` map,
  # while `~/.config/opencode/opencode.json` uses the v2 `mcp.servers.<name>`
  # shape.
  #
  # API keys are read at connect time through omp's `!command` indirection, so
  # no key material lands in the store and omp does not depend on the fish-only
  # `CONTEXT7_API_KEY`/`KAGI_API_KEY` exports of the OpenCode module. A failed
  # read drops the header/env entry instead of sending a bogus value.
  mcpServers = {
    context7 = {
      type = "http";
      url = "https://mcp.context7.com/mcp";
      headers.CONTEXT7_API_KEY = "!cat $HOME/.config/sops-nix/secrets/context7/api-key";
    };
    kagi-search = {
      type = "stdio";
      command = "uvx";
      args = [ "kagimcp" ];
      env.KAGI_API_KEY = "!cat $HOME/.config/sops-nix/secrets/kagi/api-key";
    };
  };
in
{
  # omp (Oh My Pi) — terminal-based coding agent with multi-model support.
  # Only available in nixpkgs-unstable (absent from stable 26.05), so it is
  # pulled from pkgs-unstable. Config, auth and sessions live under ~/.omp;
  # that directory is persisted via impermanence (see
  # modules/home-manager/persistence/default.nix).
  home = {
    packages = [ pkgs-unstable.omp ];

    # `~/.omp/agent/mcp.json` is omp's primary user-level MCP config. It stays a
    # read-only store symlink on purpose: `/mcp add|enable|disable` then fails
    # loudly instead of writing into a file the next activation would overwrite.
    # Add servers here instead.
    file.".omp/agent/mcp.json".text = builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
      inherit mcpServers;
    };

    # The guard must land as a regular file: omp's ambient hook discovery skips
    # symlinks, so `home.file` (which links into the store) would not be loaded.
    # It also cannot be declared in `~/.omp/agent/config.yml` via
    # `xdg.configFile`: omp rewrites that file for `omp config set`, `/settings`,
    # and model-role assignment, and the read-only store symlink makes those
    # writes fail with EACCES.
    activation.installOmpSopsGuard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      OMP_HOOK_DIR="$HOME/.omp/agent/hooks/pre"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$OMP_HOOK_DIR"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 ${sopsGuard} "$OMP_HOOK_DIR/secret-access-guard.js"
    '';
  };
}
