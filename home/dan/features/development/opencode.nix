{ pkgs, ... }:
{
  # opencode: 2.x prebuilt npm binary, packaged in overlays/opencode.
  # bun: required at runtime so OpenCode can install npm plugins (openspec, litellm).
  # opencode-plugin-litellm autodetects a LiteLLM proxy on localhost:4000/8000/8080;
  # otherwise set LITELLM_BASE_URL / LITELLM_API_KEY.
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
    "plugins" = [
      "opencode-plugin-openspec"
      {
        "package" = "opencode-plugin-litellm";
        "options" = {
          "providerID" = "litellm-ai-hub";
        };
      }
    ];
    "providers" = {
      "litellm-ai-hub" = {
        "name" = "ai hub (proxy)";
        "package" = "@opencode/ai/providers/openai-compatible";
      };
    };
  };
}
