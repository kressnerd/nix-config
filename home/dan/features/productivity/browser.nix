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

  home.activation.linkLibrewolfProfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    LIBREWOLF_DIR="$HOME/Library/Application Support/LibreWolf"
    FIREFOX_DIR="$HOME/Library/Application Support/Firefox"

    mkdir -p "$LIBREWOLF_DIR"

    # Link profiles.ini
    rm -f "$LIBREWOLF_DIR/profiles.ini"
    ln -sf "$FIREFOX_DIR/profiles.ini" "$LIBREWOLF_DIR/profiles.ini"

    # Link Profiles directory
    if [ ! -L "$LIBREWOLF_DIR/Profiles" ]; then
      rm -rf "$LIBREWOLF_DIR/Profiles"
      ln -sf "$FIREFOX_DIR/Profiles" "$LIBREWOLF_DIR/Profiles"
    fi
  '';
}
