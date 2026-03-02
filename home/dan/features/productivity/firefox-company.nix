{
  config,
  pkgs,
  lib,
  ...
}: let
  addons = pkgs.nur.repos.rycee.firefox-addons;
  exts = import ../../../../lib/firefox-extensions.nix {inherit addons;};

  kagiSearch = {
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
        definedAliases = ["@g"];
      };
    };
  };

  workSettings = {
    # Privacy: delete cookies, sessions, offline data on shutdown
    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.clearOnShutdown.cookies" = true;
    "privacy.clearOnShutdown.offlineApps" = true;
    "privacy.clearOnShutdown.sessions" = true;

    # Preserve across restarts
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.downloads" = false;
    "privacy.clearOnShutdown.cache" = false;
    "privacy.clearOnShutdown.formdata" = false;
    "privacy.clearOnShutdown.siteSettings" = false;

    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "network.cookie.cookieBehavior" = 5; # reject cross-site and social trackers
    "dom.security.https_only_mode" = true;
    "geo.enabled" = false;
    "network.dns.disablePrefetch" = true;
    "network.prefetch-next" = false;
    "browser.send_pings" = false;
    "beacon.enabled" = false;
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;
    "network.IDN_show_punycode" = true;
    "browser.formfill.enable" = false;

    # UI
    "browser.startup.page" = 3; # restore previous session
    "browser.toolbars.bookmarks.visibility" = "always";
    "webgl.disabled" = false;
    "extensions.treestyletab.show-in-browser-action" = false;
  };
in {
  programs.firefox.profiles = {
    company = {
      id = 0;
      name = "company";
      isDefault = true;

      extensions.packages =
        exts.common
        ++ exts.dev
        ++ exts.privacy
        ++ exts.productivity
        ++ exts.convenience
        ++ (with addons; [
          multi-account-containers
          link-cleaner
        ]);

      settings =
        workSettings
        // {
          "privacy.resistFingerprinting" = false;
        };

      search = kagiSearch;
    };

    client001 = {
      id = 1;
      name = "client001";
      isDefault = false;

      extensions.packages =
        exts.common
        ++ exts.convenience
        ++ exts.dev
        ++ exts.privacy
        ++ exts.productivity
        ++ (with addons; [
          multi-account-containers
        ]);

      settings =
        workSettings
        // {
          "privacy.resistFingerprinting" = true;
        };

      search = kagiSearch;
    };

    client002 = {
      id = 2;
      name = "client002";
      isDefault = false;

      extensions.packages =
        exts.common
        ++ exts.convenience
        ++ exts.dev
        ++ exts.privacy
        ++ exts.productivity
        ++ (with addons; [
          multi-account-containers
          onepassword-password-manager
        ]);

      settings =
        workSettings
        // {
          "privacy.resistFingerprinting" = false;
        };

      search = kagiSearch;
    };
  };
}
