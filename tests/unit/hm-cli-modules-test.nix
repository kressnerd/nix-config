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
    myHome = {
      persistence = {
        enable = false;
      };
    };
  };
  mockPkgsLinux = pkgs // {
    stdenv = pkgs.stdenv // {
      hostPlatform = {
        isDarwin = false;
        isLinux = true;
      };
    };
  };
  mockPkgsDarwin = pkgs // {
    stdenv = pkgs.stdenv // {
      hostPlatform = {
        isDarwin = true;
        isLinux = false;
      };
    };
  };
  mockConfigWithSecrets = mockConfig // {
    sops = {
      placeholder = mockConfig.sops.placeholder // {
        "git/company/name" = "<placeholder>";
        "git/company/email" = "<placeholder>";
        "git/company/folder" = "<placeholder>";
        "git/client001/name" = "<placeholder>";
        "git/client001/email" = "<placeholder>";
        "git/client001/folder" = "<placeholder>";
        "git/client002/name" = "<placeholder>";
        "git/client002/email" = "<placeholder>";
        "git/client002/folder" = "<placeholder>";
      };
      secrets = {
        "git/company/name" = { };
        "git/company/folder" = { };
        "git/client001/name" = { };
        "git/client001/folder" = { };
        "git/client002/name" = { };
        "git/client002/folder" = { };
      };
      templates = { };
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
  gitModuleWithSecrets = import ../../home/dan/features/cli/git.nix {
    config = mockConfigWithSecrets;
    pkgs = mockPkgsDarwin;
    inherit lib;
  };

  # ── ssh.nix ─────────────────────────────────────────────────────────────────
  sshModuleDarwin = import ../../home/dan/features/cli/ssh.nix {
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

  testVimNoCatppuccinColorscheme = {
    expr = builtins.match ".*catppuccin.*" vimModule.programs.vim.extraConfig == null;
    expected = true;
  };

  testVimExtraConfigLeader = {
    expr = lib.strings.hasInfix "let mapleader" vimModule.programs.vim.extraConfig;
    expected = true;
  };

  testVimNoCatppuccinPlugin = {
    expr = builtins.all (p: (p.pname or p.name or "") != "catppuccin-vim") (
      vimModule.programs.vim.plugins or [ ]
    );
    expected = true;
  };

  testVimStylixTargetEnabled = {
    expr = vimModule.stylix.targets.vim.enable;
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

  # ── git: multi-identity templates ───────────────────────────────────────────
  testGitPersonalSshCommand = {
    expr =
      lib.strings.hasInfix
        "sshCommand = \"ssh -i ~/.ssh/id_ed25519_personal_2026-10-04 -o IdentitiesOnly=yes\""
        gitModuleDarwin.sops.templates."git-personal".content;
    expected = true;
  };

  testGitPersonalUrlInsteadOf = {
    expr =
      lib.strings.hasInfix "[url \"git@github-personal:\"]"
        gitModuleDarwin.sops.templates."git-personal".content
      &&
        lib.strings.hasInfix "insteadOf = git@github.com:"
          gitModuleDarwin.sops.templates."git-personal".content;
    expected = true;
  };

  testGitCompanySshCommand = {
    expr =
      lib.strings.hasInfix
        "sshCommand = \"ssh -i ~/.ssh/id_ed25519_company_2025-06-18 -o IdentitiesOnly=yes\""
        gitModuleWithSecrets.sops.templates."git-company".content;
    expected = true;
  };

  testGitCompanyUrlInsteadOf = {
    expr =
      lib.strings.hasInfix "[url \"git@github-company:\"]"
        gitModuleWithSecrets.sops.templates."git-company".content
      &&
        lib.strings.hasInfix "insteadOf = git@github.com:"
          gitModuleWithSecrets.sops.templates."git-company".content;
    expected = true;
  };

  testGitClient001SshCommand = {
    expr =
      lib.strings.hasInfix
        "sshCommand = \"ssh -i ~/.ssh/id_ed25519_client001_2025-07-22 -o IdentitiesOnly=yes\""
        gitModuleWithSecrets.sops.templates."git-client001".content;
    expected = true;
  };

  testGitClient001UrlInsteadOf = {
    expr =
      lib.strings.hasInfix "[url \"git@github-client001:\"]"
        gitModuleWithSecrets.sops.templates."git-client001".content
      &&
        lib.strings.hasInfix "insteadOf = git@github.com:"
          gitModuleWithSecrets.sops.templates."git-client001".content;
    expected = true;
  };

  testGitClient002SshCommand = {
    expr =
      lib.strings.hasInfix
        "sshCommand = \"ssh -i ~/.ssh/id_ed25519_client002_2026-01-13 -o IdentitiesOnly=yes\""
        gitModuleWithSecrets.sops.templates."git-client002".content;
    expected = true;
  };

  testGitClient002UrlInsteadOf = {
    expr =
      lib.strings.hasInfix "[url \"git@bitbucket-client002:\"]"
        gitModuleWithSecrets.sops.templates."git-client002".content
      &&
        lib.strings.hasInfix "insteadOf = git@bitbucket.org:"
          gitModuleWithSecrets.sops.templates."git-client002".content;
    expected = true;
  };

  # ── ssh: settings ────────────────────────────────────────────────────────────
  testSshGithubPersonalKey = {
    expr = sshModuleDarwin.programs.ssh.settings."github-personal".IdentityFile;
    expected = "~/.ssh/id_ed25519_personal_2026-10-04";
  };

  testSshDarwinWildcardIdentitiesOnly = {
    expr = sshModuleDarwin.programs.ssh.settings."*".IdentitiesOnly or null;
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
