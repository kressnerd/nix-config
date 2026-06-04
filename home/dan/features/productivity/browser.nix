{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Firefox theme managed manually — install a light theme addon from the browser extension store
  programs.firefox = {
    enable = true;

    package =
      if pkgs.stdenv.isDarwin then
        null # pre-installed externally
      else
        pkgs.firefox;

    policies = {
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
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
      SanitizeOnShutdown = {
        Cache = true;
        Cookies = true;
        OfflineApps = true;
        Sessions = true;
      };
      "3rdparty".extensions = {
        "uBlock@raymondhill.net" = {
          permissions = [ "internal.privateBrowsingAllowed" ];
          origins = [ ];
        };
        "gdpr@cavi.au.dk" = {
          permissions = [ "<all_urls>" ];
          origins = [ "<all_urls>" ];
        };
      };
    };
  };

  home = lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [
      ".cache/mozilla"
      ".mozilla"
    ];
  };
}
