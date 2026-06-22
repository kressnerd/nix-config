{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    # opencode: from dan-online/opencode-nix overlay (auto-updated from GitHub releases).
    # bun: required at runtime so OpenCode can install npm plugins (e.g. opencode-plugin-openspec).
    home.packages = [
      pkgs.opencode
      pkgs.bun
    ];

    # Global opencode config — managed declaratively by home-manager.
    # OpenCode installs plugins listed here via bun at startup;
    # cache lands in ~/.cache/opencode/node_modules/ (persisted separately on thiniel).
    xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      plugin = [ "opencode-plugin-openspec" ];
    };
  }
  (lib.mkIf config.myHome.persistence.enable {
    # thiniel uses impermanence (btrfs root wipe on boot): persist auth state and plugin cache.
    # opencode.json itself is a home-manager symlink — no need to persist it.
    home.persistence.${config.myHome.persistence.root}.directories = [
      ".local/share/opencode"
      ".cache/opencode"
    ];
  })
]
