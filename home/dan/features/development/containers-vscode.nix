{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: {
  # VS Code dev container integration with Podman
  # No additional packages needed - uses existing Podman setup

  # VS Code dev container settings
  programs.vscode = {
    profiles.default.userSettings = {
      # Dev Container configuration
      "dev.containers.dockerPath" = "${pkgs.podman}/bin/podman";
      "dev.containers.dockerComposePath" = "${pkgs.podman-compose}/bin/podman-compose";
      "dev.containers.defaultExtensions" = [
        "ms-vscode.vscode-json"
        "ms-vscode-remote.remote-containers"
      ];

      # Container development settings
      "dev.containers.executeInWSL" = false;
      "dev.containers.gitCredentialHelperConfigLocation" = "system";
      "dev.containers.copyGitConfig" = true;
      "dev.containers.forwardPorts" = true;

      # Podman specific settings
      "dev.containers.dockerSocketPath" = "/run/user/1000/podman/podman.sock";
    };
  };

  # Example devcontainer configurations
  home.file.".config/devcontainers/nodejs/.devcontainer.json".text = builtins.toJSON {
    name = "Node.js Development";
    image = "node:20-bullseye";

    features = {
      "ghcr.io/devcontainers/features/git:1" = {};
      "ghcr.io/devcontainers/features/github-cli:1" = {};
    };

    customizations = {
      vscode = {
        extensions = [
          "dbaeumer.vscode-eslint"
          "esbenp.prettier-vscode"
          "ms-vscode.vscode-typescript-next"
        ];
        settings = {
          "terminal.integrated.defaultProfile.linux" = "bash";
        };
      };
    };

    forwardPorts = [3000 8000 8080];
    postCreateCommand = "npm install -g pnpm yarn";

    mounts = [
      "source=${config.home.homeDirectory}/.ssh,target=/home/node/.ssh,type=bind,consistency=cached"
      "source=${config.home.homeDirectory}/.gitconfig,target=/home/node/.gitconfig,type=bind,consistency=cached"
    ];

    remoteUser = "node";
  };

  home.file.".config/devcontainers/python/.devcontainer.json".text = builtins.toJSON {
    name = "Python Development";
    image = "python:3.11-bullseye";

    features = {
      "ghcr.io/devcontainers/features/git:1" = {};
      "ghcr.io/devcontainers/features/python:1" = {
        version = "3.11";
        installTools = true;
      };
    };

    customizations = {
      vscode = {
        extensions = [
          "ms-python.python"
          "ms-python.pylint"
          "ms-python.black-formatter"
          "ms-toolsai.jupyter"
        ];
        settings = {
          "python.defaultInterpreterPath" = "/usr/local/bin/python";
          "python.linting.enabled" = true;
          "python.linting.pylintEnabled" = true;
          "python.formatting.provider" = "black";
        };
      };
    };

    forwardPorts = [8000 5000 8080];
    postCreateCommand = "pip install --upgrade pip && pip install poetry black pylint";

    mounts = [
      "source=${config.home.homeDirectory}/.ssh,target=/root/.ssh,type=bind,consistency=cached"
      "source=${config.home.homeDirectory}/.gitconfig,target=/root/.gitconfig,type=bind,consistency=cached"
    ];
  };

  home.file.".config/devcontainers/rust/.devcontainer.json".text = builtins.toJSON {
    name = "Rust Development";
    image = "rust:1.75-bullseye";

    features = {
      "ghcr.io/devcontainers/features/git:1" = {};
      "ghcr.io/devcontainers/features/rust:1" = {};
    };

    customizations = {
      vscode = {
        extensions = [
          "rust-lang.rust-analyzer"
          "tamasfe.even-better-toml"
          "serayuzgur.crates"
        ];
        settings = {
          "rust-analyzer.checkOnSave.command" = "clippy";
        };
      };
    };

    forwardPorts = [8000 3030];
    postCreateCommand = "rustup component add clippy rustfmt";

    mounts = [
      "source=${config.home.homeDirectory}/.ssh,target=/root/.ssh,type=bind,consistency=cached"
      "source=${config.home.homeDirectory}/.gitconfig,target=/root/.gitconfig,type=bind,consistency=cached"
      "source=${config.home.homeDirectory}/.cargo,target=/usr/local/cargo,type=bind,consistency=cached"
    ];
  };

  # Shell helper for dev containers
  programs.fish = {
    shellAliases = {
      "devcontainer-build" = "devcontainer build --workspace-folder";
      "devcontainer-up" = "devcontainer up --workspace-folder";
    };

    functions = {
      # Dev container helper functions
      devcontainer-create = ''
        set name $argv[1]
        set template $argv[2]
        set target_dir $argv[3]

        if test -z "$name"
          set name "devcontainer"
        end
        if test -z "$template"
          set template "nodejs"
        end
        if test -z "$target_dir"
          set target_dir "."
        end

        if not test -d "$target_dir"
          echo "Error: Directory $target_dir does not exist"
          return 1
        end

        set template_dir "${config.home.homeDirectory}/.config/devcontainers/$template"
        if not test -d "$template_dir"
          echo "Error: Template $template not found"
          echo "Available templates:"
          ls "${config.home.homeDirectory}/.config/devcontainers/"
          return 1
        end

        mkdir -p "$target_dir/.devcontainer"
        cp "$template_dir/.devcontainer.json" "$target_dir/.devcontainer/"
        echo "Created devcontainer configuration in $target_dir/.devcontainer/"
        echo "Open in VS Code and run 'Dev Containers: Reopen in Container'"
      '';

      devcontainer-list-templates = ''
        echo "Available devcontainer templates:"
        ls "${config.home.homeDirectory}/.config/devcontainers/" | sed 's/^/  /'
      '';
    };
  };

  # Devcontainer directories now created centrally in containers-common.nix
}
