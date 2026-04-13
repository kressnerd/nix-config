# tests/unit/hm-cli-modules-test.nix
# Characterization unit tests for home/dan/features/cli/* modules.
# All tests capture existing behavior and must pass against the current codebase.
{ lib, pkgs }:
let
  # ── fish.nix ────────────────────────────────────────────────────────────────
  fishModule = import ../../home/dan/features/cli/fish.nix { inherit pkgs; };
  fishAliases = fishModule.programs.fish.shellAliases;
  fishPkgNames = builtins.map (p: p.pname or p.name or "") fishModule.home.packages;

  # ── starship.nix ────────────────────────────────────────────────────────────
  starshipModule = import ../../home/dan/features/cli/starship.nix { inherit lib; };
  starshipSettings = starshipModule.programs.starship.settings;

  # ── vim.nix ─────────────────────────────────────────────────────────────────
  vimModule = import ../../home/dan/features/cli/vim.nix { inherit pkgs; };

  # ── git.nix ─────────────────────────────────────────────────────────────────
  # Provide a minimal config mock.  The sops.placeholder values are only used
  # inside string-interpolated template content which is not tested here, so
  # returning placeholder strings is sufficient.
  mockConfig = {
    sops = {
      placeholder = {
        "git/personal/name" = "<placeholder>";
        "git/personal/email" = "<placeholder>";
        "git/personal/folder" = "<placeholder>";
      };
      secrets = { };
      templates = { };
    };
    home = {
      homeDirectory = "/home/dan";
    };
  };
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
  gitModuleLinux = import ../../home/dan/features/cli/git.nix {
    config = mockConfig;
    pkgs = mockPkgsLinux;
    inherit lib;
  };
  gitModuleDarwin = import ../../home/dan/features/cli/git.nix {
    config = mockConfig;
    pkgs = mockPkgsDarwin;
    inherit lib;
  };

  # ── cloud-tools.nix ─────────────────────────────────────────────────────────
  cloudToolsModule = import ../../home/dan/features/cli/cloud-tools.nix { inherit pkgs; };
  cloudToolsPkgNames = builtins.map (p: p.pname or p.name or "") cloudToolsModule.home.packages;
in
lib.debug.runTests {

  # ── fish: enable ────────────────────────────────────────────────────────────
  testFishEnabled = {
    expr = fishModule.programs.fish.enable;
    expected = true;
  };

  # ── fish: individual aliases ────────────────────────────────────────────────
  testFishAliasLl = {
    expr = fishAliases.ll;
    expected = "ls -la";
  };

  testFishAliasLt = {
    expr = fishAliases.lt;
    expected = "eza --tree";
  };

  testFishAliasGs = {
    expr = fishAliases.gs;
    expected = "git status";
  };

  testFishAliasSsh = {
    expr = fishAliases.ssh;
    expected = "kitty +kitten ssh";
  };

  testFishAliasDotDot = {
    expr = fishAliases."..";
    expected = "cd ..";
  };

  testFishHasLaAlias = {
    expr = builtins.hasAttr "la" fishAliases;
    expected = true;
  };

  testFishHasLAlias = {
    expr = builtins.hasAttr "l" fishAliases;
    expected = true;
  };

  testFishHasGAlias = {
    expr = builtins.hasAttr "g" fishAliases;
    expected = true;
  };

  testFishHasVAlias = {
    expr = builtins.hasAttr "v" fishAliases;
    expected = true;
  };

  testFishHasViAlias = {
    expr = builtins.hasAttr "vi" fishAliases;
    expected = true;
  };

  testFishHasIcatAlias = {
    expr = builtins.hasAttr "icat" fishAliases;
    expected = true;
  };

  testFishHasDotDotDotAlias = {
    expr = builtins.hasAttr "..." fishAliases;
    expected = true;
  };

  testFishHasDotDotDotDotAlias = {
    expr = builtins.hasAttr "...." fishAliases;
    expected = true;
  };

  # ── fish: interactiveShellInit ───────────────────────────────────────────────
  testFishInteractiveInitViMode = {
    expr = lib.strings.hasInfix "fish_vi_key_bindings" fishModule.programs.fish.interactiveShellInit;
    expected = true;
  };

  testFishInteractiveInitKitty = {
    expr = lib.strings.hasInfix "KITTY_INSTALLATION_DIR" fishModule.programs.fish.interactiveShellInit;
    expected = true;
  };

  testFishInteractiveInitGreeting = {
    expr = lib.strings.hasInfix "set fish_greeting" fishModule.programs.fish.interactiveShellInit;
    expected = true;
  };

  # ── fish: functions ──────────────────────────────────────────────────────────
  testFishFunctionGs = {
    expr = fishModule.programs.fish.functions ? gs;
    expected = true;
  };

  testFishFunctionMkcd = {
    expr = fishModule.programs.fish.functions ? mkcd;
    expected = true;
  };

  # ── fish: sdkman plugin package ──────────────────────────────────────────────
  testFishSdkmanPlugin = {
    expr = builtins.any (n: lib.strings.hasInfix "sdkman" n) fishPkgNames;
    expected = true;
  };

  # ── starship: enable ─────────────────────────────────────────────────────────
  testStarshipEnabled = {
    expr = starshipModule.programs.starship.enable;
    expected = true;
  };

  testStarshipDirectoryStyle = {
    expr = starshipSettings.directory.style;
    expected = "bold blue";
  };

  testStarshipNoPalette = {
    expr = starshipSettings ? palettes;
    expected = false;
  };

  testStarshipTruncationLength = {
    expr = starshipSettings.directory.truncation_length;
    expected = 3;
  };

  testStarshipSubstitutionPersonal = {
    expr = starshipSettings.directory.substitutions ? "~/dev/personal";
    expected = true;
  };

  testStarshipCmdDurationMinTime = {
    expr = starshipSettings.cmd_duration.min_time;
    expected = 500;
  };

  testStarshipFormatGitBranch = {
    expr = lib.strings.hasInfix "$git_branch" starshipSettings.format;
    expected = true;
  };

  testStarshipFormatNixShell = {
    expr = lib.strings.hasInfix "$nix_shell" starshipSettings.format;
    expected = true;
  };

  # ── vim: settings ────────────────────────────────────────────────────────────
  testVimEnabled = {
    expr = vimModule.programs.vim.enable;
    expected = true;
  };

  testVimExpandtab = {
    expr = vimModule.programs.vim.settings.expandtab;
    expected = true;
  };

  testVimShiftwidth = {
    expr = vimModule.programs.vim.settings.shiftwidth;
    expected = 2;
  };

  testVimTabstop = {
    expr = vimModule.programs.vim.settings.tabstop;
    expected = 2;
  };

  testVimRelativenumber = {
    expr = vimModule.programs.vim.settings.relativenumber;
    expected = true;
  };

  testVimSmartcase = {
    expr = vimModule.programs.vim.settings.smartcase;
    expected = true;
  };

  testVimExtraConfigCatppuccin = {
    expr = lib.strings.hasInfix "catppuccin_latte" vimModule.programs.vim.extraConfig;
    expected = true;
  };

  testVimExtraConfigLeader = {
    expr = lib.strings.hasInfix "let mapleader" vimModule.programs.vim.extraConfig;
    expected = true;
  };

  testVimHasCatppuccinPlugin = {
    expr = builtins.any (p: (p.pname or p.name or "") == "catppuccin-vim") vimModule.programs.vim.plugins;
    expected = true;
  };

  # ── git: enable + ignores ────────────────────────────────────────────────────
  testGitEnabled = {
    expr = gitModuleLinux.programs.git.enable;
    expected = true;
  };

  testGitIgnoresDirenv = {
    expr = builtins.elem ".direnv" gitModuleLinux.programs.git.ignores;
    expected = true;
  };

  testGitIgnoresDarwinSpecificOnDarwin = {
    expr = builtins.elem ".DS_Store" gitModuleDarwin.programs.git.ignores;
    expected = true;
  };

  testGitIgnoresNoDarwinOnLinux = {
    expr = !(builtins.elem ".DS_Store" gitModuleLinux.programs.git.ignores);
    expected = true;
  };

  # ── cloud-tools: packages ────────────────────────────────────────────────────
  testCloudToolsHasGoogleCloudSdk = {
    expr = builtins.any (n: lib.strings.hasInfix "google-cloud-sdk" n) cloudToolsPkgNames;
    expected = true;
  };

  testCloudToolsHasTenv = {
    expr = builtins.elem "tenv" cloudToolsPkgNames;
    expected = true;
  };

  # ── cloud-tools: aliases ──────────────────────────────────────────────────────
  testCloudToolsAliasGcp = {
    expr = cloudToolsModule.programs.fish.shellAliases.gcp;
    expected = "gcloud config list project --format='value(core.project)'";
  };

  testCloudToolsAliasGcs = {
    expr = cloudToolsModule.programs.fish.shellAliases.gcs;
    expected = "gcloud config set project";
  };

  testCloudToolsAliasGcl = {
    expr = cloudToolsModule.programs.fish.shellAliases.gcl;
    expected = "gcloud config list";
  };
}
