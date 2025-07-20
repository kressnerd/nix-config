{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.firefox = {
    enable = true;
    package = pkgs.librewolf;

    profiles = {
      personal = {
        id = 0;
        name = "personal";
        isDefault = false;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.tabs.firefox-view" = false;
        };

        search = {
          force = true;
          default = "ddg";

          engines = {
            "Kagi" = {
              urls = [
                {
                  template = "https://kagi.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "https://kagi.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = ["@k"];
            };
          };
        };
      };

      company = {
        # Don't use sops in the key name
        id = 1;
        name = "company";
        isDefault = true;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
        };

        search = {
          force = true;
          default = "google";
        };
      };

      client001 = {
        id = 2;
        name = "client001";
        isDefault = false;

        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";
        };

        search = {
          force = true;
          default = "ddg";
        };
      };
    };
  };

  # Create the mapping file
  sops.templates."browser-profile-mapping" = {
    content = ''
      # Browser Profile to Folder Mapping
      personal=${config.sops.placeholder."git/personal/folder"}
      company=${config.sops.placeholder."git/company/folder"}
      client001=${config.sops.placeholder."git/client001/folder"}
    '';
    path = "${config.home.homeDirectory}/.config/browser-profiles.env";
  };

  # Update profile names AFTER everything else
  home.activation.updateFirefoxProfileNames = lib.hm.dag.entryAfter ["writeBoundary" "sops-nix" "linkGeneration"] ''
    echo "Updating Firefox profile names..."

    if [ -f "$HOME/.config/browser-profiles.env" ]; then
      source "$HOME/.config/browser-profiles.env"
      echo "Loaded mappings: personal=$personal, company=$company, client001=$client001"

      # Update both Firefox and LibreWolf profiles.ini
      for dir in "Firefox" "LibreWolf"; do
        PROFILES_INI="$HOME/Library/Application Support/$dir/profiles.ini"
        if [ -f "$PROFILES_INI" ]; then
          echo "Updating $PROFILES_INI"

          # Use perl instead of sed for better compatibility
          ${pkgs.perl}/bin/perl -i -pe "s/Name=personal/Name=$personal/g" "$PROFILES_INI"
          ${pkgs.perl}/bin/perl -i -pe "s/Name=company/Name=$company/g" "$PROFILES_INI"
          ${pkgs.perl}/bin/perl -i -pe "s/Name=client001/Name=$client001/g" "$PROFILES_INI"

          echo "Updated content:"
          cat "$PROFILES_INI"
        fi
      done
    else
      echo "browser-profiles.env not found!"
    fi
  '';

  # Link LibreWolf to Firefox profiles (run BEFORE updateFirefoxProfileNames)
  home.activation.linkLibrewolfProfiles = lib.hm.dag.entryBefore ["updateFirefoxProfileNames"] ''
    mkdir -p "$HOME/Library/Application Support/LibreWolf"

    # Don't link profiles.ini anymore - we'll update it separately
    # Just link the Profiles directory
    if [ ! -L "$HOME/Library/Application Support/LibreWolf/Profiles" ]; then
      rm -rf "$HOME/Library/Application Support/LibreWolf/Profiles"
      ln -sf "$HOME/Library/Application Support/Firefox/Profiles" \
             "$HOME/Library/Application Support/LibreWolf/Profiles"
    fi

    # Copy profiles.ini instead of linking
    cp "$HOME/Library/Application Support/Firefox/profiles.ini" \
       "$HOME/Library/Application Support/LibreWolf/profiles.ini"
  '';
}
