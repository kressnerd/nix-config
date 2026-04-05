# tests/unit/helpers-test.nix
# Unit tests for lib/helpers.nix
{ lib }:
let
  helpers = import ../../lib/helpers.nix;

  # mkFirefoxExtensions needs an `addons` attrset. We build a minimal fake
  # that only provides the attribute names actually referenced in helpers.nix,
  # each mapped to a distinct string so we can verify list membership.
  fakeAddons = {
    # common
    ublock-origin = "ublock-origin";
    keepassxc-browser = "keepassxc-browser";
    consent-o-matic = "consent-o-matic";
    # dev
    refined-github = "refined-github";
    octotree = "octotree";
    wappalyzer = "wappalyzer";
    # privacy
    privacy-badger = "privacy-badger";
    decentraleyes = "decentraleyes";
    clearurls = "clearurls";
    noscript = "noscript";
    temporary-containers = "temporary-containers";
    # productivity
    tridactyl = "tridactyl";
    tree-style-tab = "tree-style-tab";
    languagetool = "languagetool";
    single-file = "single-file";
    # convenience
    sponsorblock = "sponsorblock";
    return-youtube-dislikes = "return-youtube-dislikes";
    youtube-shorts-block = "youtube-shorts-block";
    reddit-enhancement-suite = "reddit-enhancement-suite";
    old-reddit-redirect = "old-reddit-redirect";
  };

  exts = helpers.mkFirefoxExtensions { addons = fakeAddons; };
in
lib.debug.runTests {
  # ── Top-level structure ──────────────────────────────────────────────────

  testHelpersIsAttrSet = {
    expr = builtins.isAttrs helpers;
    expected = true;
  };

  testHelpersMkPkgsUnstableIsFunction = {
    expr = builtins.isFunction helpers.mkPkgsUnstable;
    expected = true;
  };

  testHelpersMkFirefoxExtensionsIsFunction = {
    expr = builtins.isFunction helpers.mkFirefoxExtensions;
    expected = true;
  };

  # ── mkFirefoxExtensions — result structure ───────────────────────────────

  testExtensionsResultIsAttrSet = {
    expr = builtins.isAttrs exts;
    expected = true;
  };

  testExtensionsHasCommon = {
    expr = exts ? common;
    expected = true;
  };

  testExtensionsHasDev = {
    expr = exts ? dev;
    expected = true;
  };

  testExtensionsHasPrivacy = {
    expr = exts ? privacy;
    expected = true;
  };

  testExtensionsHasProductivity = {
    expr = exts ? productivity;
    expected = true;
  };

  testExtensionsHasConvenience = {
    expr = exts ? convenience;
    expected = true;
  };

  # ── mkFirefoxExtensions — list types ────────────────────────────────────

  testCommonIsList = {
    expr = builtins.isList exts.common;
    expected = true;
  };

  testDevIsList = {
    expr = builtins.isList exts.dev;
    expected = true;
  };

  testPrivacyIsList = {
    expr = builtins.isList exts.privacy;
    expected = true;
  };

  testProductivityIsList = {
    expr = builtins.isList exts.productivity;
    expected = true;
  };

  testConvenienceIsList = {
    expr = builtins.isList exts.convenience;
    expected = true;
  };

  # ── mkFirefoxExtensions — list lengths ──────────────────────────────────

  testCommonLength = {
    expr = builtins.length exts.common;
    expected = 3;
  };

  testDevLength = {
    expr = builtins.length exts.dev;
    expected = 3;
  };

  testPrivacyLength = {
    expr = builtins.length exts.privacy;
    expected = 5;
  };

  testProductivityLength = {
    expr = builtins.length exts.productivity;
    expected = 4;
  };

  testConvenienceLength = {
    expr = builtins.length exts.convenience;
    expected = 5;
  };

  # ── mkFirefoxExtensions — spot-check membership ──────────────────────────

  testCommonContainsUblockOrigin = {
    expr = builtins.elem "ublock-origin" exts.common;
    expected = true;
  };

  testCommonContainsKeepassxcBrowser = {
    expr = builtins.elem "keepassxc-browser" exts.common;
    expected = true;
  };

  testCommonContainsConsentOMatic = {
    expr = builtins.elem "consent-o-matic" exts.common;
    expected = true;
  };

  testDevContainsRefinedGithub = {
    expr = builtins.elem "refined-github" exts.dev;
    expected = true;
  };

  testPrivacyContainsPrivacyBadger = {
    expr = builtins.elem "privacy-badger" exts.privacy;
    expected = true;
  };

  testPrivacyContainsNoscript = {
    expr = builtins.elem "noscript" exts.privacy;
    expected = true;
  };

  testProductivityContainsTridactyl = {
    expr = builtins.elem "tridactyl" exts.productivity;
    expected = true;
  };

  testConvenienceContainsSponsorblock = {
    expr = builtins.elem "sponsorblock" exts.convenience;
    expected = true;
  };

  testConvenienceContainsOldRedditRedirect = {
    expr = builtins.elem "old-reddit-redirect" exts.convenience;
    expected = true;
  };

  # ── mkFirefoxExtensions — cross-list isolation ───────────────────────────
  # Items from one list must NOT bleed into another

  testCommonDoesNotContainRefinedGithub = {
    expr = builtins.elem "refined-github" exts.common;
    expected = false;
  };

  testDevDoesNotContainUblockOrigin = {
    expr = builtins.elem "ublock-origin" exts.dev;
    expected = false;
  };

  testPrivacyDoesNotContainSponsorblock = {
    expr = builtins.elem "sponsorblock" exts.privacy;
    expected = false;
  };

  testProductivityDoesNotContainNoscript = {
    expr = builtins.elem "noscript" exts.productivity;
    expected = false;
  };

  testConvenienceDoesNotContainTridactyl = {
    expr = builtins.elem "tridactyl" exts.convenience;
    expected = false;
  };

  # ── mkPkgsUnstable — argument type (function accepts a set) ─────────────
  # We cannot actually call mkPkgsUnstable without real nixpkgs flake inputs,
  # so we only verify it is a lambda (already done above) and that it accepts
  # the expected argument names via builtins.functionArgs.

  testMkPkgsUnstableExpectsNixpkgsUnstable = {
    expr = (builtins.functionArgs helpers.mkPkgsUnstable) ? nixpkgs-unstable;
    expected = true;
  };

  testMkPkgsUnstableExpectsSystem = {
    expr = (builtins.functionArgs helpers.mkPkgsUnstable) ? system;
    expected = true;
  };

  # mkFirefoxExtensions expects exactly `addons`
  testMkFirefoxExtensionsExpectsAddons = {
    expr = (builtins.functionArgs helpers.mkFirefoxExtensions) ? addons;
    expected = true;
  };
}
