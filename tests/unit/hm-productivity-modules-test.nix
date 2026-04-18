# tests/unit/hm-productivity-modules-test.nix
# Characterization unit tests for Home Manager productivity feature modules.
# Captures existing behaviour as-is so any regression is immediately visible.
# Covers: browser.nix, keepassxc.nix, maestral.nix
{ lib, pkgs }:
let
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

  # browser.nix — signature is `{ pkgs, ... }:`
  browserModuleLinux = import ../../home/dan/features/productivity/browser.nix {
    pkgs = mockPkgsLinux;
  };
  browserModuleDarwin = import ../../home/dan/features/productivity/browser.nix {
    pkgs = mockPkgsDarwin;
  };
  linuxPolicies = browserModuleLinux.programs.firefox.policies;

  # keepassxc.nix — signature is `_:`, call with empty attrset
  keepassxcModule = import ../../home/dan/features/productivity/keepassxc.nix { };

  # maestral.nix — signature is `{ pkgs, ... }:`
  maestralModule = import ../../home/dan/features/productivity/maestral.nix {
    pkgs = mockPkgsLinux;
  };
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
}
