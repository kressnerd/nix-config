{pkgs, ...}: let
  addons = pkgs.nur.repos.rycee.firefox-addons;
  exts = import ../../../../lib/firefox-extensions.nix {inherit addons;};
in {
  programs.firefox.profiles.user = {
    id = 0;
    isDefault = true;

    extensions.packages =
      exts.common
      ++ exts.privacy
      ++ exts.convenience
      ++ exts.productivity
      ++ (with addons; [
        terms-of-service-didnt-read
        link-cleaner
        tabliss
        kagi-search
      ]);

    settings = {
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

      "privacy.resistFingerprinting" = true;
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

      # Disable built-in password manager
      "signon.rememberSignons" = false;
      "signon.autofillForms" = false;
      "signon.formlessCapture.enabled" = false;

      # Disable translation for German
      "browser.translations.neverTranslateLanguages" = "de";

      # UI / browser
      "app.update.channel" = "default";
      "browser.search.defaultenginename" = "Kagi";
      "browser.search.order.1" = "Kagi";
      "browser.aboutConfig.showWarning" = false;
      "browser.compactmode.show" = true;
      "browser.cache.disk.enable" = false;
      "webgl.disabled" = false;
    };

    search = {
      force = true;
      default = "Kagi";

      engines = {
        google.metaData.hidden = true;
        bing.metaData.hidden = true;
        ebay.metaData.hidden = true;
        amazondotcom-us.metaData.hidden = true;
        wikipedia.metaData.hidden = true;

        "Kagi" = {
          urls = [
            {
              template = "https://kagi.com/search?";
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
}
