{
  config,
  lib,
  pkgs,
  ...
}: {
  # macOS user-specific settings
  targets.darwin = {
    defaults = {
      NSGlobalDomain = {
        # Graphite accent color
        AppleAccentColor = -1; # -1 for Graphite
        AppleHighlightColor = "0.847059 0.847059 0.862745 Graphite";

        # Interface and interaction
        # AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3; # Full keyboard access
        ApplePressAndHoldEnabled = false; # Key repeat instead of accents
      };

      # Dock settings
      "com.apple.dock" = {
        # Position
        orientation = "left";

        # Auto-hide behavior
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.5;

        # Dock content and appearance
        show-recents = false;
        tilesize = 48;
        minimize-to-application = true;
        mineffect = "scale"; # or "genie"

        # Don't rearrange spaces based on use
        mru-spaces = false;
      };

      # Finder settings
      "com.apple.finder" = {
        # Show all file extensions
        AppleShowAllExtensions = true;

        # Show path and status bars
        ShowPathbar = true;
        ShowStatusBar = true;

        # Default to list view
        FXPreferredViewStyle = "Nlsv";
      };

      # Disable "natural" scrolling if you prefer
      # NSGlobalDomain.com.apple.swipescrolldirection = false;
    };

    # These settings require a re-login to fully take effect
    currentHostDefaults = {
      "com.apple.controlcenter" = {
        # Menu bar customization
        "NSStatusItem Visible WiFi" = true;
        "NSStatusItem Visible Bluetooth" = true;
        "NSStatusItem Visible Sound" = true;
      };
    };
  };
}
