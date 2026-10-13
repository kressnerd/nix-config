# The GitHub fetch credential of a machine that develops and builds this
# configuration: the value is recorded only encrypted (`github/access-token` in
# the machine's own `secrets.yaml`); system activation renders it, owned by the
# device owner with mode 0400, into a nix configuration fragment that the
# machine's nix configuration includes. Nothing prepared by hand, and no local
# account other than the owner (and root by privilege) can read it.
{ config, lib, ... }:
let
  cfg = config.mySystem.githubFetchCredential;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    sops.secrets."github/access-token" = { };

    sops.templates."nix-github-access-tokens" = {
      content = "access-tokens = github.com=${config.sops.placeholder."github/access-token"}\n";
      owner = cfg.user;
      mode = "0400";
    };

    # `!include` tolerates a missing or unreadable fragment, so a machine whose
    # credential is not yet rendered keeps working unauthenticated.
    nix.extraOptions = "!include ${config.sops.templates."nix-github-access-tokens".path}\n";
  };
}
