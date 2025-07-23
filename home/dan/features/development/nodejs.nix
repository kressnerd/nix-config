{
  config,
  pkgs,
  lib,
  ...
}: {
  # Node.js v20 development packages - updated
  home.packages = with pkgs; [
    # Node.js runtime (includes npm)
    nodejs_20
  ];

  # Shell integration
  programs.zsh = {
    shellAliases = {
      "node20" = "${pkgs.nodejs_20}/bin/node";
      "npm20" = "${pkgs.nodejs_20}/bin/npm";
    };
  };

  # Environment variables for Node.js
  home.sessionVariables = {
    NODE_PATH = "${pkgs.nodejs_20}/lib/node_modules";
  };
}
