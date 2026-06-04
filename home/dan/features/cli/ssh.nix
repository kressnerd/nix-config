{
  config,
  lib,
  pkgs,
  ...
}:
{
  # SSH agent as systemd user service (Linux only; macOS uses launchd agent)
  services.ssh-agent.enable = !pkgs.stdenv.isDarwin;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      "config.d/company"
      "config.d/client002"
      "config.d/nix-builder"
    ];

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions =
          if pkgs.stdenv.isDarwin then
            {
              UseKeychain = "yes";
              IgnoreUnknown = "UseKeychain";
            }
          else
            { };
      };

      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal_2025-06-18";
        identitiesOnly = true;
      };

      "github-company" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_company_2025-06-18";
        identitiesOnly = true;
      };

      "github-client001" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_client001_2025-07-22";
        identitiesOnly = true;
      };

      "bitbucket-client002" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_client002_2026-01-13";
        identitiesOnly = true;
      };
    };
  };

  home.persistence.${config.myHome.persistence.root}.directories =
    lib.mkIf config.myHome.persistence.enable
      [ ".ssh" ];
}
