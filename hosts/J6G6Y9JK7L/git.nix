{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # Static default values (will be overridden by includeIf)
    userName = "Daniel Kressner";
    userEmail = "noreply@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };

      alias = {
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        whoami = "!git config user.name && git config user.email";
      };
    };
  };

  sops.templates = {
    "git-personal" = {
      content = ''
        [user]
            name = ${config.sops.placeholder."git/personal/name"}
            email = ${config.sops.placeholder."git/personal/email"}

        [commit]
            gpgsign = false

        [core]
            sshCommand = ssh -i ~/.ssh/id_ed25519 -F /dev/null
      '';
      path = "${config.home.homeDirectory}/.config/git/personal";
    };

    "git-company" = {
      content = ''
        [user]
            name = ${config.sops.placeholder."git/company/name"}
            email = ${config.sops.placeholder."git/company/email"}

        [commit]
            gpgsign = false

        [core]
            sshCommand = ssh -i ~/.ssh/id_ed25519 -F /dev/null
      '';
      path = "${config.home.homeDirectory}/.config/git/company";
    };

    "git-client001" = {
      content = ''
        [user]
            name = ${config.sops.placeholder."git/client001/name"}
            email = ${config.sops.placeholder."git/client001/email"}

        [commit]
            gpgsign = false

        [core]
            sshCommand = ssh -i ~/.ssh/id_ed25519 -F /dev/null
      '';
      path = "${config.home.homeDirectory}/.config/git/client001";
    };
  };

  # Use activation script to update gitconfig with dynamic paths
  home.activation.setupGitIncludes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Read the actual folder names from sops
    PERSONAL_FOLDER=$(cat "${config.sops.secrets."git/personal/folder".path}")
    COMPANY_FOLDER=$(cat "${config.sops.secrets."git/company/folder".path}")
    CLIENT_FOLDER=$(cat "${config.sops.secrets."git/client001/folder".path}")

    # Add the includeIf entries with the actual folder names
    ${pkgs.git}/bin/git config --global includeIf."gitdir:~/dev/$PERSONAL_FOLDER/".path "~/.config/git/personal"
    ${pkgs.git}/bin/git config --global includeIf."gitdir:~/dev/$COMPANY_FOLDER/".path "~/.config/git/company"
    ${pkgs.git}/bin/git config --global includeIf."gitdir:~/dev/$CLIENT_FOLDER/".path "~/.config/git/client001"
  '';

  # SSH configuration
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

      "github-client" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
    };
  };
}
