{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Disable nix-darwin's Nix management (required for Determinate Nix)
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  # Add fish to /etc/shells for macOS
  environment.shells = [pkgs.fish];

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

  # Declaratively set user shell - runs after user creation
  system.activationScripts.users.text = lib.mkAfter ''
    echo "Setting default shell to fish for ${config.system.primaryUser}..."
    CURRENT_SHELL=$(dscl . -read /Users/${config.system.primaryUser} UserShell 2>/dev/null | awk '{print $2}')
    DESIRED_SHELL="${pkgs.fish}/bin/fish"

    if [ "$CURRENT_SHELL" != "$DESIRED_SHELL" ]; then
      echo "Changing shell from $CURRENT_SHELL to $DESIRED_SHELL"
      dscl . -create /Users/${config.system.primaryUser} UserShell "$DESIRED_SHELL"
      echo "✓ Shell updated successfully"
    else
      echo "✓ Shell already set to fish"
    fi
  '';

  # System packages (prefer Home-Manager for user packages)
  environment.systemPackages = with pkgs; [
    # Only system-wide essentials
  ];
}
