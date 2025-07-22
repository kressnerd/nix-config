{ config, pkgs, lib, ... }:

{
  home.packages = [ pkgs.git ];

  sops.templates = {
    "gitconfig" = {
      content = ''
        [user]
            name = ${config.sops.placeholder."git/personal/name"}
            email = ${config.sops.placeholder."git/personal/email"}

        [init]
            defaultBranch = main

        [core]
            editor = vim
            autocrlf = input

        [includeIf "gitdir:~/dev/${config.sops.placeholder."git/personal/folder"}/"]
            path = ~/.config/git/personal

        [includeIf "gitdir:~/dev/${config.sops.placeholder."git/company/folder"}/"]
            path = ~/.config/git/company

        [includeIf "gitdir:~/dev/${config.sops.placeholder."git/client001/folder"}/"]
            path = ~/.config/git/client001

        [alias]
            lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
            whoami = !git config user.name && git config user.email
      '';
      path = "${config.home.homeDirectory}/.gitconfig";
    };

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
}
