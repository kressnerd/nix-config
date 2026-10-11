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
in
{
  # omp (Oh My Pi) — terminal-based coding agent with multi-model support.
  # Only available in nixpkgs-unstable (absent from stable 26.05), so it is
  # pulled from pkgs-unstable. Config, auth and sessions live under ~/.omp;
  # that directory is persisted via impermanence (see
  # modules/home-manager/persistence/default.nix).
  home.packages = [ pkgs-unstable.omp ];

  # The guard must land as a regular file: omp's ambient hook discovery skips
  # symlinks, so `home.file` (which links into the store) would not be loaded.
  # It also cannot be declared in `~/.omp/agent/config.yml` via
  # `xdg.configFile`: omp rewrites that file for `omp config set`, `/settings`,
  # and model-role assignment, and the read-only store symlink makes those
  # writes fail with EACCES.
  home.activation.installOmpSopsGuard = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    OMP_HOOK_DIR="$HOME/.omp/agent/hooks/pre"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$OMP_HOOK_DIR"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 ${sopsGuard} "$OMP_HOOK_DIR/secret-access-guard.js"
  '';
}
