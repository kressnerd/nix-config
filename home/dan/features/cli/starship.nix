{ lib, ... }:
{
  stylix.targets.starship.enable = true;

  programs.starship = {
    enable = true;

    settings = {
      # Overall prompt format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$nodejs"
        "$python"
        "$rust"
        "$golang"
        "$java"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      # Module configurations
      username = {
        show_always = false;
        style_user = "blue bold";
        style_root = "red bold";
        format = "[$user]($style) ";
        disabled = false;
      };

      hostname = {
        ssh_only = true;
        style = "bold green";
        format = "[@$hostname]($style) ";
      };

      directory = {
        style = "bold blue";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " 󰌾";

        substitutions = {
          "~/dev/personal" = " ";
          "~/dev/company" = " ";
          "~/dev/client001" = " ";
          "~/dev/client002" = " ";
          "~/Documents" = "󰈙 ";
          "~/Downloads" = " ";
          "~/Music" = " ";
          "~/Pictures" = " ";
          "~" = " ";
          "/" = "󰞌 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bold green";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold red";
        format = "([$all_status$ahead_behind]($style)) ";
      };

      nix_shell = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$state( \($name\))]($style) ";
      };

      cmd_duration = {
        min_time = 500;
        style = "bold yellow";
        format = "[$duration]($style) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vicmd_symbol = "[❮](bold green)";
      };

      # Language modules
      nodejs = {
        symbol = " ";
        style = "bold green";
        format = "[$symbol($version )]($style)";
      };

      python = {
        symbol = " ";
        style = "bold yellow";
        format = "[$symbol($version )]($style)";
      };

      rust = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol($version )]($style)";
      };

      golang = {
        symbol = " ";
        style = "bold cyan";
        format = "[$symbol($version )]($style)";
      };

      java = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol($version )]($style)";
      };
    };
  };
}
