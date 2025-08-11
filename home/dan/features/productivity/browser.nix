{
  config,
  pkgs,
  lib,
  ...
}: let
  addons = pkgs.nur.repos.rycee.firefox-addons;

  # Common extensions for all profiles
  commonExtensions = with addons; [
    ublock-origin # Ad blocker
    keepassxc-browser # Password manager
    darkreader # Dark mode for websites
    consent-o-matic
  ];

  # Development extensions
  devExtensions = with addons; [
    # react-devtools
    refined-github
    octotree # GitHub code tree
    wappalyzer # Technology profiler
  ];

  # Privacy extensions
  privacyExtensions = with addons; [
    privacy-badger
    decentraleyes
    clearurls
    temporary-containers
  ];

  # Productivity extensions
  productivityExtensions = with addons; [
    tridactyl
    # vimium                 # Vim keybindings
    tree-style-tab # Vertical tabs
    sidebery # Alternative vertical tabs
    # onepassword-password-manager
    languagetool # Grammar checker
    single-file # Save complete web pages
  ];

  convinienceExtensions = with addons; [
    sponsorblock # Skip YouTube sponsors
    return-youtube-dislikes
    youtube-shorts-block
    reddit-enhancement-suite
    old-reddit-redirect
    # bypass-paywalls-clean
  ];
in {
  programs.librewolf = {
    enable = true;

    profiles = {
      company = {
        id = 0;
        name = "company";
        isDefault = true;

        extensions.packages =
          commonExtensions
          ++ devExtensions
          ++ convinienceExtensions
          ++ (with addons; [
            multi-account-containers
            # aws-sso-container
            link-cleaner
            # markdown-viewer-webext
          ]);

        settings = {
          "privacy.clearOnShutdown.cookies" = true;
          "privacy.clearOnShutdown.offlineApps" = true;
          "privacy.clearOnShutdown.sessions" = true;
          "privacy.resistFingerprinting" = true;
          "privacy.sanitize.sanitizeOnShutdown" = false; # Ensure overall sanitization is off

          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.formdata" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";

          "privacy.clearOnShutdown.siteSettings" = false;

          "webgl.disabled" = false;

          # Extension-specific settings
          "extensions.treestyletab.show-in-browser-action" = false; # Hide TST from toolbar
        };

        search = {
          force = true;
          default = "Kagi";
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

      client001 = {
        id = 1;
        name = "client001";
        isDefault = false;

        extensions.packages =
          commonExtensions
          ++ convinienceExtensions
          ++ (with addons; [
            multi-account-containers
            # foxyproxy
          ]);

        settings = {
          "privacy.clearOnShutdown.cookies" = true;
          "privacy.clearOnShutdown.offlineApps" = true;
          "privacy.clearOnShutdown.sessions" = true;
          "privacy.resistFingerprinting" = true;
          "privacy.sanitize.sanitizeOnShutdown" = false; # Ensure overall sanitization is off

          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "privacy.clearOnShutdown.cache" = false;
          "privacy.clearOnShutdown.formdata" = false;
          "browser.startup.page" = 3;
          "browser.toolbars.bookmarks.visibility" = "always";

          "privacy.clearOnShutdown.siteSettings" = false;

          "webgl.disabled" = false;

          # Extension-specific settings
          "extensions.treestyletab.show-in-browser-action" = false; # Hide TST from toolbar
        };

        search = {
          force = true;
          default = "Kagi";
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
    };
  };
}
