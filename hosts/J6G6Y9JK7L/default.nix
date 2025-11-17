{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Disable nix-darwin's Nix management (required for Determinate Nix)
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  # PRIMARY USER - Required for Homebrew
  system.primaryUser = "daniel.kressner";

  users.users."daniel.kressner" = {
    name = "daniel.kressner";
    home = "/Users/daniel.kressner";
    shell = pkgs.fish;
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "daniel.kressner";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "score-spec/homebrew-tap" = inputs.score-spec-tap;
    };
    mutableTaps = false;
  };

  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = true;
    };
    brews = ["score-compose"];
    casks = [
      "crossover"
      "keepassxc"
    ];
  };

  # Activation script to check Xcode CLT at runtime
  system.activationScripts.extraActivation.text = ''
    echo "Checking for Xcode Command Line Tools..."
    if ! /usr/bin/xcode-select -p &>/dev/null; then
      echo ""
      echo "WARNING: Xcode Command Line Tools are not installed!"
      echo "Homebrew will not work without them."
      echo ""
      echo "Please install by running:"
      echo "  xcode-select --install"
      echo ""
      echo "Note: The system configuration will still apply, but Homebrew operations may fail."
      echo ""
    else
      echo "✓ Xcode Command Line Tools found at: $(/usr/bin/xcode-select -p)"
    fi
  '';

  # System packages (prefer Home-Manager for user packages)
  environment.systemPackages = with pkgs; [
    # Only system-wide essentials
  ];
}
