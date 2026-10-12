{
  config,
  lib,
  pkgs,
  ...
}:
let
  # A host has work identity configuration to connect with exactly when it
  # declares that identity's secret material. A device that holds none renders
  # no connection entry for it.
  holdsIdentity = identity: config.sops.secrets ? "git/${identity}/name";
in
{
  # SSH agent as systemd user service (Linux only; macOS uses launchd agent)
  services.ssh-agent.enable = !pkgs.stdenv.hostPlatform.isDarwin;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Manually maintained configuration files, declared by the host that keeps
    # them. A device that keeps none includes none.
    includes = config.myHome.ssh.includedConfigs;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
        IdentitiesOnly = true;
      };

      # The device's personal identity: the key it holds.
      "github-personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = config.myHome.ssh.personalIdentityFile;
        IdentitiesOnly = true;
      };
    }
    // lib.optionalAttrs (holdsIdentity "company") {
      "github-company" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_company_2025-06-18";
        IdentitiesOnly = true;
      };
    }
    // lib.optionalAttrs (holdsIdentity "client001") {
      "github-client001" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_client001_2025-07-22";
        IdentitiesOnly = true;
      };
    }
    // lib.optionalAttrs (holdsIdentity "client002") {
      "bitbucket-client002" = {
        HostName = "bitbucket.org";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_client002_2026-01-13";
        IdentitiesOnly = true;
      };
    };
  };

  home = lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [ ".ssh" ];
  };
}
