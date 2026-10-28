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
      if pkgs.stdenv.hostPlatform.isDarwin then
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
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    # Home Manager 26.05 resolves `configPath` to the relative XDG path, but its
    # wrapper exports `MOZ_APP_DATA` only when `configPath` differs from that
    # resolved default. The device therefore states the absolute path: the
    # profile data lives there (change `quiet-configuration-evaluation`), and
    # the persisted set follows it. On darwin the browser keeps the platform
    # default, which is why this setting is stated for Linux only — the module
    # is shared with the work MacBook.
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  home = lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [
      ".cache/mozilla"
      # The browser profile moved from .mozilla to the XDG config directory; the
      # persisted path follows it so browsing state still survives the root reset.
      ".config/mozilla"
    ];
  };
}
