{ pkgs, ... }:
let
  # Duplicated from hyprland.nix — will be replaced by Stylix tokens in Phase 7
  catppuccinLatte = {
    base = "#eff1f5";
    text = "#4c4f69";
    lavender = "#7287fd";
  };

  removeHash = s: builtins.substring 1 (builtins.stringLength s - 1) s;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.kitty}/bin/kitty";
        icons-enabled = "yes";
        width = 50;
        font = "monospace:size=11";
        line-height = 25;
        lines = 10;
        letter-spacing = 0;
      };
      colors = {
        background = "${removeHash catppuccinLatte.base}ff";
        text = "${removeHash catppuccinLatte.text}ff";
        match = "${removeHash catppuccinLatte.lavender}ff";
        selection = "${removeHash catppuccinLatte.lavender}ff";
        selection-text = "${removeHash catppuccinLatte.base}ff";
        border = "${removeHash catppuccinLatte.lavender}ff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
