# The GitHub fetch credential of a machine that develops and builds this
# configuration: the value is recorded only encrypted (`github/access-token` in
# the machine's own `secrets.yaml`); system activation renders it, owned by the
# device owner with mode 0400, into a nix configuration fragment that the
# machine's nix configuration includes. Nothing prepared by hand, and no local
# account other than the owner (and root by privilege) can read it.
{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.mySystem.githubFetchCredential;
in
{
  imports = [ ./options.nix ];

  # `imports` alone would be enough on a host that carries the sops module, but
  # `hosts/common/global` imports this pair on every NixOS host — and a false
  # `mkIf` does not remove a definition whose option does not exist, so a host
  # without the sops module (nixos-vm-minimal) would fail to evaluate. The
  # option-presence guard (static, unlike `config ? …`, which recurses) keeps the
  # option available everywhere while a host that does not carry sops-nix
  # declares nothing.
  config = lib.mkIf cfg.enable (
    lib.optionalAttrs (options ? sops) {
      sops.secrets."github/access-token" = { };

      sops.templates."nix-github-access-tokens" = {
        content = "access-tokens = github.com=${config.sops.placeholder."github/access-token"}\n";
        owner = cfg.user;
        mode = "0400";
      };

      # `!include` tolerates a missing or unreadable fragment, so a machine whose
      # credential is not yet rendered keeps working unauthenticated.
      nix.extraOptions = "!include ${config.sops.templates."nix-github-access-tokens".path}\n";
    }
  );
}
