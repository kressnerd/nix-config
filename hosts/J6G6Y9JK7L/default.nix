{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # Disable nix-darwin's Nix management (required for Determinate Nix)
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  # Add fish to /etc/shells for macOS
  environment.shells = [ pkgs.fish ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    # Set Git commit hash for darwin-version
    configurationRevision = null;

    # Used for backwards compatibility
    stateVersion = 6;

    # PRIMARY USER - Required for Homebrew
    primaryUser = "daniel.kressner";

    activationScripts = {
      # Activation script to check Xcode CLT at runtime
      extraActivation.text = ''
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

      # Set user shell - runs after user creation
      users.text = lib.mkAfter ''
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
    };
  };

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
    brews = [ "score-compose" ];
    casks = [
      "cameracontroller"
      "claude"
      "claude-code"
      "crossover"
      "kitty"
      "marta"
    ];
  };

  # System packages (prefer Home-Manager for user packages)
  environment.systemPackages = with pkgs; [
    # Only system-wide essentials
  ];

  # --- Stylix: system-wide One Light theming ---
  # autoEnable = false: HM feature modules already have hand-crafted theming;
  # Stylix HM targets are enabled selectively to avoid conflicts.
  stylix = {
    enable = true;
    autoEnable = false;
    polarity = "light";
    base16Scheme = {
      scheme = "One Light";
      author = "Daniel Pfeifer (http://github.com/purpleKarrot)";
      base00 = "fafafa";
      base01 = "f0f0f1";
      base02 = "e5e5e6";
      base03 = "a0a1a7";
      base04 = "696c77";
      base05 = "383a42";
      base06 = "202227";
      base07 = "090a0b";
      base08 = "ca1243";
      base09 = "d75f00";
      base0A = "c18401";
      base0B = "50a14f";
      base0C = "0184bc";
      base0D = "4078f2";
      base0E = "a626a4";
      base0F = "986801";
    };
    image = pkgs.runCommand "one-light-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 1920x1080 xc:#fafafa $out
    '';
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        terminal = 12;
      };
    };
  };
}
