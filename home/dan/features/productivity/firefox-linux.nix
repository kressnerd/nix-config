{
  config,
  pkgs,
  inputs,
  ...
}: {
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        SponsoredPocket = false;
        Snippets = false;
      };
      "3rdparty".extensions = {
        "uBlock@raymondhill.net" = {
          permissions = ["internal.privateBrowsingAllowed"];
          origins = [];
        };
        "gdpr@cavi.au.dk" = {
          permissions = ["<all_urls>"];
          origins = ["<all_urls>"];
        };
      };
    };

    profiles = {
      "user" = {
        id = 0;
        isDefault = true;

        extensions.packages = with inputs.firefox-addons.packages.${pkgs.system}; [
          ublock-origin
          sponsorblock
          return-youtube-dislikes
          youtube-shorts-block
          privacy-badger

          consent-o-matic
          terms-of-service-didnt-read

          clearurls
          link-cleaner

          tabliss
          darkreader
          tridactyl
          kagi-search
        ];

        settings = {
          "app.update.channel" = "default";
          "browser.search.defaultenginename" = "Kagi";
          "browser.search.order.1" = "Kagi";
          "browser.aboutConfig.showWarning" = false;
          "browser.compactmode.show" = true;
          "browser.cache.disk.enable" = false;
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
              definedAlias = "@g";
            };
          };
        };
      };
    };
  };
}
