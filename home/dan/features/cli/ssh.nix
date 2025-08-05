{config, ...}: {
  programs.ssh = {
    enable = true;

    # Automatically add keys to SSH agent
    addKeysToAgent = "yes";

    # Use macOS keychain to store passphrases
    extraConfig = ''
      UseKeychain yes
      IgnoreUnknown UseKeychain
    '';

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
