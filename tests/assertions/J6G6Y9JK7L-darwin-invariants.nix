# tests/assertions/J6G6Y9JK7L-darwin-invariants.nix
# Darwin-level (nix-darwin system) invariants for J6G6Y9JK7L.
# The HM-level file tests/assertions/J6G6Y9JK7L-invariants.nix cannot see
# nix-darwin system options such as `homebrew.*`, hence this second module.
{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.homebrew.onActivation.cleanup == "zap";
      message = "J6G6Y9JK7L: homebrew.onActivation.cleanup must be \"zap\", got ${config.homebrew.onActivation.cleanup}";
    }
    {
      # A program on the device may rewrite a file the home profile renders.
      # Without a displacement command Home Manager refuses the foreign file and
      # aborts the activation; see the change `managed-file-displacement`.
      assertion =
        config.home-manager.backupCommand != null
        && lib.hasInfix "hm-displace-managed-file" (toString config.home-manager.backupCommand);
      message = "J6G6Y9JK7L: home-manager.backupCommand must be the repository's displacement command, so a rewritten managed file is renamed aside instead of aborting the activation";
    }
    {
      assertion = config.homebrew.onActivation.extraFlags == [ ];
      message = "J6G6Y9JK7L: homebrew.onActivation.extraFlags must be empty — nix-darwin 26.05 emits --zap --force-cleanup for cleanup = \"zap\" itself";
    }
    # Scenario: The work MacBook declares the credential it presents to the GitHub host
    {
      # nix-darwin does not manage /etc/nix/nix.conf on this machine, so root's
      # client owns its own user configuration; it must name the same rendered
      # fragment the owner's configuration includes (root reads it by privilege).
      assertion =
        config.system.activationScripts ? "nixGithubAccessTokens"
        && lib.hasInfix "!include ${config.home-manager.users."daniel.kressner".sops.templates."nix-github-access-tokens".path}" config.system.activationScripts.nixGithubAccessTokens.text;
      message = "J6G6Y9JK7L: an activation script must write root's nix user configuration with the credential include";
    }
  ];
}
