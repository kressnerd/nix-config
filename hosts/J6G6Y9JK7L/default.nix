{ config, pkgs, inputs, ... }:

{
  # Disable nix-darwin's Nix management (required for Determinate Nix)
  nix.enable = false;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version
  system.configurationRevision = null;

  # Used for backwards compatibility
  system.stateVersion = 6;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # PRIMARY USER - Required for Homebrew
  system.primaryUser = "daniel.kressner";

  # User configuration
  users.users."daniel.kressner" = {
    name = "daniel.kressner";
    home = "/Users/daniel.kressner";
  };

  # Fully declarative Homebrew configuration
  nix-homebrew = {
    enable = true;

    # Apple Silicon: Also install Homebrew for Intel (Rosetta 2)
    # Important for CrossOver and other x86-only apps
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = "daniel.kressner";

    # Declarative tap management
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };

    # Fully immutable - taps can only be managed through this config
    mutableTaps = false;
  };

  # Declarative Homebrew packages
  homebrew = {
    enable = true;

    # Fully declarative
    onActivation = {
      cleanup = "zap"; # Remove unlisted packages
      autoUpdate = false; # update through flake inputs
      upgrade = true; # Apply updates when switching
    };

    # Brew packages (CLI tools as fallback)
    brews = [
      # Example: tools not in nixpkgs
      # "mas" # Mac App Store CLI
    ];

    # Cask packages (GUI apps)
    casks = [
      # "crossover"
      # Add other GUI apps not available in nixpkgs
      # "microsoft-teams" # if needed
      # "zoom"
    ];

    # Mac App Store apps (requires 'mas' brew)
    # masApps = {
    #   "Keynote" = 409183694;
    # };
  };

  # Add activation script to check Xcode CLT at runtime
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

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."daniel.kressner" = import ./home.nix;
  };
}
