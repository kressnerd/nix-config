{ pkgs, ... }:
{
  # opencode: from dan-online/opencode-nix overlay (auto-updated from GitHub releases).
  # bun: required at runtime so OpenCode can install npm plugins (e.g. opencode-plugin-openspec).
  home.packages = [
    pkgs.opencode
    pkgs.bun
  ];

  # Global opencode config — managed declaratively by home-manager.
  # OpenCode installs plugins listed here via bun at startup;
  # cache lands in ~/.cache/opencode/node_modules/.
  # Persistence on NixOS (thiniel impermanence) is handled in
  # modules/home-manager/persistence/default.nix.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-plugin-openspec" ];
  };
}
