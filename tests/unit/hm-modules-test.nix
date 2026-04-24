# tests/unit/hm-modules-test.nix
# Unit tests for Home Manager module values in home/dan/thiniel.nix
# Phase 4 RED — F-002 (nrb alias)
# Phase 5 RED — F-004 (go and uv must NOT be in shell-utils.nix)
# Phase 6 RED — F-005 (kitty keybindings must be platform-appropriate)
# Phase 7 RED — F-007 (SSH UseKeychain must NOT be present on Linux)
# Colmena Review F-002 RED — colmena must NOT be in shell-utils.nix; must be in deploy-tools.nix
# Colmena Phase 2 RED — Colmena fleet deployment aliases (cs, ct, cb, cda, call)
# Colmena Phase 3 RED — J6G6Y9JK7L Colmena aliases (cs, ct, cb, cda, call)
# Colmena Review F-004 — alias value assertions for canonical Colmena aliases
# Claude Code RED — claude-code must be in home/dan/features/development/claude-code.nix
# Claude Code F-001 — .claude must be in impermanence persisted directories
# VSCode FHS RED — vscode-fhs must be in home/dan/features/productivity/vscode-fhs.nix
{ lib, pkgs }:
let
  # Import the thiniel HM profile — call with {} since signature is { ... }:
  # Returns the raw attrset { imports, home, sops, programs, ... } without
  # invoking the module system, so programs.fish.shellAliases is a plain attrset.
  thinielModule = import ../../home/dan/thiniel.nix { };

  thinielAliases = thinielModule.programs.fish.shellAliases;

  # Keep backward-compat binding used by existing alias existence tests
  aliases = thinielAliases;

  # Import shell-utils module with real pkgs and lib to inspect home.packages.
  # shell-utils.nix has signature { pkgs, lib, ... }: and returns an attrset with home.packages.
  shellUtilsModule = import ../../home/dan/features/cli/shell-utils.nix { inherit pkgs lib; };
  shellUtilsPkgNames = builtins.map (p: p.pname or p.name or "") shellUtilsModule.home.packages;

  # Import deploy-tools module to verify colmena lives there.
  deployToolsModule = import ../../home/dan/features/cli/deploy-tools.nix { inherit pkgs; };
  deployToolsPackageNames = builtins.map (p: p.pname or p.name or "") deployToolsModule.home.packages;

  # Import claude-code feature module — file does not exist yet (RED phase).
  claudeCodeModule = import ../../home/dan/features/development/claude-code.nix {
    pkgs-unstable = pkgs;
  };
  claudeCodePkgNames = builtins.map (p: p.pname or p.name or "") claudeCodeModule.home.packages;

  # Import vscode-fhs feature module — file does not exist yet (RED phase).
  vscodeFhsModule = import ../../home/dan/features/productivity/vscode-fhs.nix {
    pkgs-unstable = pkgs;
  };
  vscodeFhsPkgNames = builtins.map (p: p.pname or p.name or "") vscodeFhsModule.home.packages;

  # Import impermanence module — signature is `_:` so call with empty attrset.
  impermanenceModule = import ../../home/dan/features/linux/impermanence.nix { };
  impermanenceDirs = impermanenceModule.home.persistence."/persist".directories;

  # Import J6G6Y9JK7L HM profile — signature is { config, pkgs, lib, ... }:
  # programs.fish.shellAliases only contains string literals so no real config/pkgs needed.
  j6Module = import ../../home/dan/J6G6Y9JK7L.nix {
    config = {
      home.homeDirectory = "/Users/daniel.kressner";
      home.path = "/nix/profile";
    };
    inherit pkgs lib;
  };
  j6Aliases = j6Module.programs.fish.shellAliases;
in
lib.debug.runTests {
  # ── F-002: nrb local alias must exist ────────────────────────────────────

  # RED: thiniel.nix has no `nrb` key — expects true, expr returns false → FAIL
  testNrbAliasExists = {
    expr = builtins.hasAttr "nrb" aliases;
    expected = true;
  };

  # ── F-004: go and uv must NOT be in shell-utils.nix home.packages ─────────

  # RED: go is currently in shell-utils.nix → expects true (not present), expr returns false → FAIL
  testGoNotInShellUtils = {
    expr = !(builtins.elem "go" shellUtilsPkgNames);
    expected = true;
  };

  # RED: uv is currently in shell-utils.nix → expects true (not present), expr returns false → FAIL
  testUvNotInShellUtils = {
    expr = !(builtins.elem "uv" shellUtilsPkgNames);
    expected = true;
  };

  # ── F-005: Kitty keybindings must be platform-appropriate ─────────────────

  # RED: current kitty.nix always emits cmd+ keys regardless of platform → FAIL on Linux
  testKittyLinuxNoCmd = {
    expr =
      let
        mockPkgsLinux = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = false;
            isLinux = true;
          };
        };
        kittyModule = import ../../home/dan/features/cli/kitty.nix { pkgs = mockPkgsLinux; };
        keybindingKeys = builtins.attrNames kittyModule.programs.kitty.keybindings;
      in
      !(builtins.any (k: lib.strings.hasPrefix "cmd+" k) keybindingKeys);
    expected = true;
  };

  # PASS: current kitty.nix uses cmd+ which is correct for Darwin
  testKittyDarwinUsesCmd = {
    expr =
      let
        mockPkgsDarwin = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = true;
            isLinux = false;
          };
        };
        kittyModule = import ../../home/dan/features/cli/kitty.nix { pkgs = mockPkgsDarwin; };
        keybindingKeys = builtins.attrNames kittyModule.programs.kitty.keybindings;
      in
      builtins.any (k: lib.strings.hasPrefix "cmd+" k) keybindingKeys;
    expected = true;
  };

  # ── ssh-agent: services.ssh-agent.enable must be platform-conditional ─────

  testSshAgentEnabledOnLinux = {
    expr =
      let
        mockPkgsLinux = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = false;
            isLinux = true;
          };
        };
        mockConfig.myHome.persistence = {
          enable = false;
          root = "/persist";
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix {
          inherit lib;
          pkgs = mockPkgsLinux;
          config = mockConfig;
        };
      in
      sshModule.services.ssh-agent.enable;
    expected = true;
  };

  testSshAgentDisabledOnDarwin = {
    expr =
      let
        mockPkgsDarwin = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = true;
            isLinux = false;
          };
        };
        mockConfig.myHome.persistence = {
          enable = false;
          root = "/persist";
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix {
          inherit lib;
          pkgs = mockPkgsDarwin;
          config = mockConfig;
        };
      in
      sshModule.services.ssh-agent.enable;
    expected = false;
  };

  # ── F-007: SSH UseKeychain must only be present on macOS ──────────────────

  # RED: current ssh.nix uses `_:` and always sets UseKeychain regardless of
  # platform → expects true (not present on Linux), expr returns false → FAIL
  testSshLinuxNoUseKeychain = {
    expr =
      let
        mockPkgsLinux = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = false;
            isLinux = true;
          };
        };
        mockConfig.myHome.persistence = {
          enable = false;
          root = "/persist";
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix {
          inherit lib;
          pkgs = mockPkgsLinux;
          config = mockConfig;
        };
        extraOpts = sshModule.programs.ssh.matchBlocks."*".extraOptions;
      in
      !(builtins.hasAttr "UseKeychain" extraOpts);
    expected = true;
  };

  # F-NEW-003: UseKeychain must be present on Darwin (macOS)
  testSshDarwinHasUseKeychain = {
    expr =
      let
        mockPkgsDarwin = pkgs // {
          stdenv = pkgs.stdenv // {
            isDarwin = true;
            isLinux = false;
          };
        };
        mockConfig.myHome.persistence = {
          enable = false;
          root = "/persist";
        };
        sshModule = import ../../home/dan/features/cli/ssh.nix {
          inherit lib;
          pkgs = mockPkgsDarwin;
          config = mockConfig;
        };
        extraOpts = sshModule.programs.ssh.matchBlocks."*".extraOptions;
      in
      builtins.hasAttr "UseKeychain" extraOpts;
    expected = true;
  };

  # ── Colmena Review F-002: colmena location ───────────────────────────────

  # RED: colmena is still in shell-utils.nix → expects false (not present), expr returns true → FAIL
  testColmenaNotInShellUtils = {
    expr = builtins.elem "colmena" shellUtilsPkgNames;
    expected = false;
  };

  # RED: deploy-tools.nix does not exist yet → will fail to import → FAIL
  testColmenaInDeployTools = {
    expr = builtins.elem "colmena" deployToolsPackageNames;
    expected = true;
  };

  # ── Colmena Phase 2: Colmena fleet deployment aliases must exist ──────────

  testThinielHasCsAlias = {
    expr = aliases ? cs;
    expected = true;
  };

  testThinielHasCtAlias = {
    expr = aliases ? ct;
    expected = true;
  };

  testThinielHasCbAlias = {
    expr = aliases ? cb;
    expected = true;
  };

  testThinielHasCdaAlias = {
    expr = aliases ? cda;
    expected = true;
  };

  testThinielHasCallAlias = {
    expr = aliases ? call;
    expected = true;
  };

  # ── Colmena Phase 3: J6G6Y9JK7L must have Colmena fleet aliases ──────────

  testJ6G6Y9JK7LHasCsAlias = {
    expr = j6Aliases ? cs;
    expected = true;
  };

  testJ6G6Y9JK7LHasCtAlias = {
    expr = j6Aliases ? ct;
    expected = true;
  };

  testJ6G6Y9JK7LHasCbAlias = {
    expr = j6Aliases ? cb;
    expected = true;
  };

  testJ6G6Y9JK7LHasCdaAlias = {
    expr = j6Aliases ? cda;
    expected = true;
  };

  testJ6G6Y9JK7LHasCallAlias = {
    expr = j6Aliases ? call;
    expected = true;
  };

  # ── Colmena Review F-004: alias value assertions ──────────────────────────

  testThinielCsAliasValue = {
    expr = thinielAliases.cs;
    expected = "colmena apply --on";
  };

  testThinielCallAliasValue = {
    expr = thinielAliases.call;
    expected = "colmena apply";
  };

  # ── Claude Code RED: claude-code must be in home.packages ────────────────

  # RED: home/dan/features/development/claude-code.nix does not exist yet →
  # import fails at eval time → nix flake check FAILS as expected.
  testClaudeCodeInPackages = {
    expr = builtins.elem "claude-code" claudeCodePkgNames;
    expected = true;
  };

  # ── F-001: .claude must be in impermanence persisted directories ─────────

  testClaudeDirInImpermanence = {
    expr = builtins.elem ".claude" impermanenceDirs;
    expected = true;
  };

  # ── VSCode FHS RED: vscode-fhs must expose home.packages ────────────────

  # RED: home/dan/features/productivity/vscode-fhs.nix does not exist yet →
  # import fails at eval time → nix flake check FAILS as expected.
  testVscodeFhsHasPackages = {
    expr = vscodeFhsModule ? home && vscodeFhsModule.home ? packages;
    expected = true;
  };

  testVscodeFhsInPackages = {
    expr = builtins.any (n: lib.strings.hasPrefix "vscode" n) vscodeFhsPkgNames;
    expected = true;
  };
}
