{
  config,
  lib,
  pkgs,
  ...
}:
{
  # SSH agent as systemd user service (Linux only; macOS uses launchd agent)
  services.ssh-agent.enable = !pkgs.stdenv.hostPlatform.isDarwin;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      "config.d/company"
      "config.d/client002"
      "config.d/nix-builder"
    ];

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        IgnoreUnknown = "UseKeychain";
        UseKeychain = "yes";
      };

      "github-personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_personal_2025-06-18";
        IdentitiesOnly = true;
      };

      "github-company" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_company_2025-06-18";
        IdentitiesOnly = true;
      };

      "github-client001" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_client001_2025-07-22";
        IdentitiesOnly = true;
      };

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
