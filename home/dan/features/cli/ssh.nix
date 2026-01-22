{config, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = ["config.d/client002"];

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          UseKeychain = "yes";
          IgnoreUnknown = "UseKeychain";
        };
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
}
