_:
let
  # Duplicated from hyprland.nix — will be replaced by Stylix tokens in Phase 7
  catppuccinLatte = {
    base = "#eff1f5";
    text = "#4c4f69";
    lavender = "#7287fd";
    red = "#d20f39";
  };
in
{
  services.mako = {
    enable = true;
    settings = {
      background-color = catppuccinLatte.base;
      text-color = catppuccinLatte.text;
      border-color = catppuccinLatte.lavender;
      progress-color = "over #ccd0da";
      "urgency=low" = {
        border-color = catppuccinLatte.text;
      };
      "urgency=high" = {
        border-color = catppuccinLatte.red;
      };
    };
  };
}
