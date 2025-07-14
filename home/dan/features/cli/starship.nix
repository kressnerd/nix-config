{ config, pkgs, lib, ... }:

{
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

      # Catppuccin Latte colors to match your Kitty theme
      palette = "catppuccin_latte";

      palettes.catppuccin_latte = {
        rosewater = "#dc8a78";
        flamingo = "#dd7878";
        pink = "#ea76cb";
        mauve = "#8839ef";
        red = "#d20f39";
        maroon = "#e64553";
        peach = "#fe640b";
        yellow = "#df8e1d";
        green = "#40a02b";
        teal = "#179299";
        sky = "#04a5e5";
        sapphire = "#209fb5";
        blue = "#1e66f5";
        lavender = "#7287fd";
        text = "#4c4f69";
        subtext1 = "#5c5f77";
        subtext0 = "#6c6f85";
        overlay2 = "#7c7f93";
        overlay1 = "#8c8fa1";
        overlay0 = "#9ca0b0";
        surface2 = "#acb0be";
        surface1 = "#bcc0cc";
        surface0 = "#ccd0da";
        base = "#eff1f5";
        mantle = "#e6e9ef";
        crust = "#dce0e8";
      };

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
        style = "bold lavender";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " 󰌾";

        substitutions = {
          "~/dev/personal" = " ";
          "~/dev/company" = " ";
          "~/dev/client001" = " ";
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
