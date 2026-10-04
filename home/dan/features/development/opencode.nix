{ pkgs, ... }:
{
  # opencode: 2.x prebuilt npm binary, packaged in overlays/opencode.
  # bun: required at runtime so OpenCode can install npm plugins (litellm).
  # uv: required at runtime for uvx to run Python-based MCP servers (kagi-search).
  # opencode-plugin-litellm autodetects a LiteLLM proxy on localhost:4000/8000/8080;
  # otherwise set LITELLM_BASE_URL / LITELLM_API_KEY.
  home.packages = [
    pkgs.opencode
    pkgs.bun
    pkgs.uv
  ];

  # Global opencode config — managed declaratively by home-manager.
  # OpenCode installs plugins listed here via bun at startup;
  # cache lands in ~/.cache/opencode/node_modules/.
  # Persistence on NixOS (thiniel impermanence) is handled in
  # modules/home-manager/persistence/default.nix.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    mcp = {
      servers = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
          };
        };
        kagi-search = {
          type = "local";
          command = [
            "uvx"
            "kagimcp"
          ];
          environment = {
            KAGI_API_KEY = "{env:KAGI_API_KEY}";
          };
        };
      };
    };
    plugin = [
      "opencode-plugin-litellm"
    ];
  };

  # Export API keys from sops-nix decrypted secrets if present
  programs.fish.shellInit = ''
    test -f ~/.config/sops-nix/secrets/context7/api-key; and set -gx CONTEXT7_API_KEY (cat ~/.config/sops-nix/secrets/context7/api-key)
    test -f ~/.config/sops-nix/secrets/kagi/api-key; and set -gx KAGI_API_KEY (cat ~/.config/sops-nix/secrets/kagi/api-key)
  '';
}
