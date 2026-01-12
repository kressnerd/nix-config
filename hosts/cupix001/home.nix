{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Home Manager configuration for cupix001
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs;};

    users.dan = {
      home.stateVersion = "25.11";

      # Minimal packages
      home.packages = with pkgs; [
        ripgrep
        fd
        bat
      ];

      # Fish shell
      programs.fish = {
        enable = true;
        shellAliases = {
          ll = "ls -lah";
          update = "sudo nixos-rebuild switch --flake /etc/nixos#cupix001";
          hsc = "headscale";
        };
      };

      # Git configuration
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "Daniel Kressner";
            email = "daniel@kressner.cloud";
          };
          init.defaultBranch = "main";
          pull.rebase = false;
        };
      };

      # Impermanence for home directory
      home.persistence."/persist/home" = {
        directories = [
          ".ssh"
          ".local/share/fish"
        ];
        files = [
          ".local/share/fish/fish_history"
        ];
      };
    };
  };
}
