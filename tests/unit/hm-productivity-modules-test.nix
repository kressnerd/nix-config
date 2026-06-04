# tests/unit/hm-productivity-modules-test.nix
# Characterization unit tests for Home Manager productivity feature modules.
# Captures existing behaviour as-is so any regression is immediately visible.
# Covers: browser.nix, keepassxc.nix, maestral.nix, firefox-personal.nix
{ lib, pkgs }:
let
  normalizeModule =
    module:
    if module ? _type && module._type == "merge" then
      lib.foldl' lib.recursiveUpdate { } (
        builtins.map (
          m: if m ? _type && m._type == "if" then if m.condition then m.content else { } else m
        ) module.contents
      )
    else
      module;

  # Platform mocks
  mockPkgsLinux = pkgs // {
    stdenv = pkgs.stdenv // {
      isDarwin = false;
      isLinux = true;
    };
  };
  mockPkgsDarwin = pkgs // {
    stdenv = pkgs.stdenv // {
      isDarwin = true;
      isLinux = false;
    };
  };

  # Superset of all addons from mkFirefoxExtensions (common, dev, privacy, productivity, convenience)
  # plus profile-specific extras. Includes dev addons for future firefox-company.nix test reuse.
  mockPkgsWithNur = mockPkgsLinux // {
    nur = {
      repos.rycee.firefox-addons = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = name;
          })
          [
            "ublock-origin"
            "keepassxc-browser"
            "consent-o-matic"
            "privacy-badger"
            "decentraleyes"
            "clearurls"
            "noscript"
            "temporary-containers"
            "tridactyl"
            "tree-style-tab"
            "languagetool"
            "single-file"
            "sponsorblock"
            "return-youtube-dislikes"
            "youtube-shorts-block"
            "reddit-enhancement-suite"
            "old-reddit-redirect"
            "terms-of-service-didnt-read"
            "link-cleaner"
            "tabliss"
            "kagi-search"
            "refined-github"
            "octotree"
            "wappalyzer"
          ]
      );
    };
  };

  firefoxPersonalModule = import ../../home/dan/features/productivity/firefox-personal.nix {
    pkgs = mockPkgsWithNur;
  };

  # browser.nix — signature is `{ config, lib, pkgs, ... }:`
  # config mock: persistence disabled so home.persistence block is a no-op
  mockPersistenceConfig = {
    myHome.persistence = {
      enable = false;
      root = "/persist";
    };
  };
  browserModuleLinux = import ../../home/dan/features/productivity/browser.nix {
    inherit lib;
    pkgs = mockPkgsLinux;
    config = mockPersistenceConfig;
  };
  browserModuleDarwin = import ../../home/dan/features/productivity/browser.nix {
    inherit lib;
    pkgs = mockPkgsDarwin;
    config = mockPersistenceConfig;
  };
  linuxPolicies = browserModuleLinux.programs.firefox.policies;

  # keepassxc.nix — signature is `_:`, call with empty attrset
  keepassxcModule = import ../../home/dan/features/productivity/keepassxc.nix { };

  # maestral.nix — signature is `{ config, lib, pkgs, ... }:`
  maestralModule = normalizeModule (
    import ../../home/dan/features/productivity/maestral.nix {
      pkgs = mockPkgsLinux;
      inherit lib;
      config = {
        myHome.persistence = {
          enable = false;
          root = "/persist";
        };
      };
    }
  );
in
lib.debug.runTests {

  # ── browser: firefox enabled ───────────────────────────────────────────────

  testFirefoxEnabled = {
    expr = browserModuleLinux.programs.firefox.enable;
    expected = true;
  };

  # ── browser: platform-conditional package ─────────────────────────────────

  testFirefoxPackageLinux = {
    expr = browserModuleLinux.programs.firefox.package;
    expected = mockPkgsLinux.firefox;
  };

  testFirefoxPackageDarwinNull = {
    expr = browserModuleDarwin.programs.firefox.package;
    expected = null;
  };

  # ── browser: policies ─────────────────────────────────────────────────────

  testFirefoxPolicyPasswordManagerDisabled = {
    expr = linuxPolicies.PasswordManagerEnabled;
    expected = false;
  };

  testFirefoxPolicyTelemetryDisabled = {
    expr = linuxPolicies.DisableTelemetry;
    expected = true;
  };

  testFirefoxPolicyTrackingProtectionEnabled = {
    expr = linuxPolicies.EnableTrackingProtection.Value;
    expected = true;
  };

  testFirefoxPolicyTrackingProtectionLocked = {
    expr = linuxPolicies.EnableTrackingProtection.Locked;
    expected = true;
  };

  testFirefoxPolicyCryptominingBlocked = {
    expr = linuxPolicies.EnableTrackingProtection.Cryptomining;
    expected = true;
  };

  testFirefoxPolicyFingerprintingBlocked = {
    expr = linuxPolicies.EnableTrackingProtection.Fingerprinting;
    expected = true;
  };

  testFirefoxPolicyPocketDisabled = {
    expr = linuxPolicies.DisablePocket;
    expected = true;
  };

  testFirefoxPolicyStudiesDisabled = {
    expr = linuxPolicies.DisableFirefoxStudies;
    expected = true;
  };

  testFirefoxPolicyAccountsDisabled = {
    expr = linuxPolicies.DisableFirefoxAccounts;
    expected = true;
  };

  testFirefoxPolicySanitizeCache = {
    expr = linuxPolicies.SanitizeOnShutdown.Cache;
    expected = true;
  };

  testFirefoxPolicySanitizeCookies = {
    expr = linuxPolicies.SanitizeOnShutdown.Cookies;
    expected = true;
  };

  testFirefoxPolicyUblockConfigured = {
    expr = linuxPolicies."3rdparty".extensions ? "uBlock@raymondhill.net";
    expected = true;
  };

  # ── keepassxc ─────────────────────────────────────────────────────────────

  testKeepassxcEnabled = {
    expr = keepassxcModule.programs.keepassxc.enable;
    expected = true;
  };

  testKeepassxcBrowserEnabled = {
    expr = keepassxcModule.programs.keepassxc.settings.Browser.Enabled;
    expected = true;
  };

  testKeepassxcSshAgentEnabled = {
    expr = keepassxcModule.programs.keepassxc.settings.SSHAgent.Enabled;
    expected = true;
  };

  testKeepassxcCompactMode = {
    expr = keepassxcModule.programs.keepassxc.settings.GUI.CompactMode;
    expected = true;
  };

  testKeepassxcHidePasswords = {
    expr = keepassxcModule.programs.keepassxc.settings.GUI.HidePasswords;
    expected = true;
  };

  # ── maestral ──────────────────────────────────────────────────────────────

  testMaestralPackagePresent = {
    expr = builtins.any (p: (p.pname or p.name or "") == "maestral") maestralModule.home.packages;
    expected = true;
  };

  testMaestralServiceDefined = {
    expr =
      maestralModule ? systemd
      && maestralModule.systemd ? user
      && maestralModule.systemd.user ? services
      && maestralModule.systemd.user.services ? maestral;
    expected = true;
  };

  testMaestralServiceExecStart = {
    expr =
      let
        svc = maestralModule.systemd.user.services.maestral;
      in
      builtins.isString svc.Service.ExecStart
      && builtins.match ".*maestral.*--foreground.*" svc.Service.ExecStart != null;
    expected = true;
  };

  testMaestralServiceWantedBy = {
    expr = maestralModule.systemd.user.services.maestral.Install.WantedBy;
    expected = [ "graphical-session.target" ];
  };

  testMaestralServiceRestart = {
    expr = maestralModule.systemd.user.services.maestral.Service.Restart;
    expected = "on-failure";
  };

  # ── firefox-personal: no-tracking profile ────────────────────────────────

  testPersonalProfileNoTrackingExists = {
    expr = firefoxPersonalModule.programs.firefox.profiles ? no-tracking;
    expected = true;
  };

  testPersonalProfileNoTrackingId = {
    expr = firefoxPersonalModule.programs.firefox.profiles.no-tracking.id;
    expected = 1;
  };

  testPersonalProfileNoTrackingNotDefault = {
    expr = firefoxPersonalModule.programs.firefox.profiles.no-tracking.isDefault;
    expected = false;
  };

  # Characterization tests — user profile unchanged
  testPersonalProfileUserExists = {
    expr = firefoxPersonalModule.programs.firefox.profiles ? user;
    expected = true;
  };

  testPersonalProfileUserId = {
    expr = firefoxPersonalModule.programs.firefox.profiles.user.id;
    expected = 0;
  };

  testPersonalProfileUserIsDefault = {
    expr = firefoxPersonalModule.programs.firefox.profiles.user.isDefault;
    expected = true;
  };

  # Characterization tests — both profiles identical
  testPersonalProfileSettingsMatch = {
    expr =
      firefoxPersonalModule.programs.firefox.profiles.user.settings
      == firefoxPersonalModule.programs.firefox.profiles.no-tracking.settings;
    expected = true;
  };

  testPersonalProfileSearchMatch = {
    expr =
      firefoxPersonalModule.programs.firefox.profiles.user.search
      == firefoxPersonalModule.programs.firefox.profiles.no-tracking.search;
    expected = true;
  };

  testPersonalProfileExtensionsMatch = {
    expr =
      firefoxPersonalModule.programs.firefox.profiles.user.extensions.packages
      == firefoxPersonalModule.programs.firefox.profiles.no-tracking.extensions.packages;
    expected = true;
  };

}
