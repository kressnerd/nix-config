{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.git pkgs.delta];

  # Git program configuration with Delta integration
  programs.git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        theme = "Dracula";
        line-numbers = true;
        side-by-side = true;
        navigate = true;
        hyperlinks = true;
        light = false;
      };
    };
  };

  sops.templates =
    {
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

          ${lib.optionalString (config.sops.secrets ? "git/company/folder") ''
            [includeIf "gitdir:~/dev/${config.sops.placeholder."git/company/folder"}/"]
                path = ~/.config/git/company
          ''}

          ${lib.optionalString (config.sops.secrets ? "git/client001/folder") ''
            [includeIf "gitdir:~/dev/${config.sops.placeholder."git/client001/folder"}/"]
                path = ~/.config/git/client001
          ''}

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

          [url "git@github-personal:"]
              insteadOf = git@github.com:
        '';
        path = "${config.home.homeDirectory}/.config/git/personal";
      };
    }
    // lib.optionalAttrs (config.sops.secrets ? "git/company/name") {
      "git-company" = {
        content = ''
          [user]
              name = ${config.sops.placeholder."git/company/name"}
              email = ${config.sops.placeholder."git/company/email"}

          [commit]
              gpgsign = false

          [url "git@github-company:"]
              insteadOf = git@github.com:
        '';
        path = "${config.home.homeDirectory}/.config/git/company";
      };
    }
    // lib.optionalAttrs (config.sops.secrets ? "git/client001/name") {
      "git-client001" = {
        content = ''
          [user]
              name = ${config.sops.placeholder."git/client001/name"}
              email = ${config.sops.placeholder."git/client001/email"}

          [commit]
              gpgsign = false

          [url "git@github-client001:"]
              insteadOf = git@github.com:
        '';
        path = "${config.home.homeDirectory}/.config/git/client001";
      };
    };
}
