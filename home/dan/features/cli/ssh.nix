{config, ...}: {
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      "github-company" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      "github-client001" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_2025-07-22-temp";
        identitiesOnly = true;
      };
    };
  };
}
