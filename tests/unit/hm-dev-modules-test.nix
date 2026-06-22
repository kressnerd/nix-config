# tests/unit/hm-dev-modules-test.nix
# Characterization unit tests for home/dan/features/development/* modules.
# All tests capture existing behavior and must pass against the current codebase.
{ lib, pkgs }:
let
  # ── formatters.nix ──────────────────────────────────────────────────────────
  formattersModule = import ../../home/dan/features/development/formatters.nix { inherit pkgs; };
  formattersPkgNames = builtins.map (p: p.pname or p.name or "") formattersModule.home.packages;

  # ── fnm.nix ─────────────────────────────────────────────────────────────────
  fnmModule = import ../../home/dan/features/development/fnm.nix { inherit pkgs; };
  fnmPkgNames = builtins.map (p: p.pname or p.name or "") fnmModule.home.packages;

  # ── nodejs.nix ──────────────────────────────────────────────────────────────
  nodejsModule = import ../../home/dan/features/development/nodejs.nix { inherit pkgs; };
  nodejsPkgNames = builtins.map (p: p.pname or p.name or "") nodejsModule.home.packages;

  # ── go.nix ──────────────────────────────────────────────────────────────────
  goModule = import ../../home/dan/features/development/go.nix { inherit pkgs; };
  goPkgNames = builtins.map (p: p.pname or p.name or "") goModule.home.packages;

  # ── jdk.nix ─────────────────────────────────────────────────────────────────
  jdkModule = import ../../home/dan/features/development/jdk.nix { inherit pkgs; };
  jdkPkgNames = builtins.map (p: p.pname or p.name or "") jdkModule.home.packages;

  # ── python-tools.nix ────────────────────────────────────────────────────────
  pythonModule = import ../../home/dan/features/development/python-tools.nix { inherit pkgs; };
  pythonPkgNames = builtins.map (p: p.pname or p.name or "") pythonModule.home.packages;

  # ── containers-podman.nix: raw source (uses config.home.homeDirectory, cannot be imported) ─
  podmanRawContent = builtins.readFile ../../home/dan/features/development/containers-podman.nix;

  # ── opencode.nix ─────────────────────────────────────────────────────────────
  # Helper: extract home.packages from a plain attrset or lib.mkMerge result.
  getHomePackages =
    module:
    if module ? home && module.home ? packages then
      module.home.packages
    else if module ? _type && module._type == "merge" then
      builtins.concatLists (
        builtins.map (m: if m ? home && m.home ? packages then m.home.packages else [ ]) module.contents
      )
    else
      [ ];

  # Helper: extract xdg.configFile from a plain attrset or lib.mkMerge result.
  getXdgConfigFiles =
    module:
    if module ? xdg && module.xdg ? configFile then
      module.xdg.configFile
    else if module ? _type && module._type == "merge" then
      builtins.foldl' (
        acc: m: if m ? xdg && m.xdg ? configFile then acc // m.xdg.configFile else acc
      ) { } module.contents
    else
      { };

  # RED: home/dan/features/development/opencode.nix does not exist yet →
  # import fails at eval time → nix build .#checks.*.unit-helpers FAILS as expected.
  opencodeModule = import ../../home/dan/features/development/opencode.nix { inherit pkgs; };
  opencodePkgNames = builtins.map (p: p.pname or p.name or "") (getHomePackages opencodeModule);
  opencodeConfigFiles = getXdgConfigFiles opencodeModule;
  opencodeJsonConfig = builtins.fromJSON opencodeConfigFiles."opencode/opencode.json".text;
in
lib.debug.runTests {

  # ── formatters: packages ─────────────────────────────────────────────────────
  testFormattersHasNixfmt = {
    expr = builtins.any (n: lib.strings.hasInfix "nixfmt" n) formattersPkgNames;
    expected = true;
  };

  testFormattersHasDeadnix = {
    expr = builtins.elem "deadnix" formattersPkgNames;
    expected = true;
  };

  testFormattersHasStatix = {
    expr = builtins.elem "statix" formattersPkgNames;
    expected = true;
  };

  testFormattersHasBlack = {
    expr = builtins.elem "black" formattersPkgNames;
    expected = true;
  };

  testFormattersHasTreefmt = {
    expr = builtins.elem "treefmt" formattersPkgNames;
    expected = true;
  };

  # ── formatters: aliases ───────────────────────────────────────────────────────
  testFormattersAliasFmtNix = {
    expr = formattersModule.programs.fish.shellAliases."fmt-nix";
    expected = "nix fmt .";
  };

  testFormattersAliasFmtAll = {
    expr = formattersModule.programs.fish.shellAliases."fmt-all";
    expected = "treefmt";
  };

  # ── formatters: treefmt config ────────────────────────────────────────────────
  testFormattersTreefmtConfigHasNixfmt = {
    expr = lib.strings.hasInfix "nixfmt" formattersModule.home.file.".treefmt.toml".text;
    expected = true;
  };

  # ── formatters: session variables ─────────────────────────────────────────────
  testFormattersBlackLineLength = {
    expr = formattersModule.home.sessionVariables.BLACK_LINE_LENGTH;
    expected = "88";
  };

  # ── formatters: fish functions ────────────────────────────────────────────────
  testFormattersFunctionFmt = {
    expr = formattersModule.programs.fish.functions ? fmt;
    expected = true;
  };

  # ── fnm: package present ──────────────────────────────────────────────────────
  testFnmHasFnm = {
    expr = builtins.elem "fnm" fnmPkgNames;
    expected = true;
  };

  # ── fnm: fish integration ─────────────────────────────────────────────────────
  testFnmFishIntegration = {
    expr = lib.strings.hasInfix "fnm env" fnmModule.programs.fish.interactiveShellInit;
    expected = true;
  };

  # ── nodejs: package present ───────────────────────────────────────────────────
  testNodejsHasNodejs = {
    expr = builtins.elem "nodejs" nodejsPkgNames;
    expected = true;
  };

  # ── go: package present ───────────────────────────────────────────────────────
  testGoHasGo = {
    expr = builtins.elem "go" goPkgNames;
    expected = true;
  };

  # ── jdk: packages present ─────────────────────────────────────────────────────
  testJdkHasZulu = {
    expr = builtins.any (n: lib.strings.hasInfix "zulu" n) jdkPkgNames;
    expected = true;
  };

  testJdkHasMaven = {
    expr = builtins.elem "maven" jdkPkgNames;
    expected = true;
  };

  # ── python-tools: package present ────────────────────────────────────────────
  testPythonHasUv = {
    expr = builtins.elem "uv" pythonPkgNames;
    expected = true;
  };

  testPythonHasPython3 = {
    expr = builtins.elem "python3" pythonPkgNames;
    expected = true;
  };

  # ── containers-podman: no duplicate aliases already defined in containers-common ─
  # These aliases are canonical in containers-common.nix; containers-podman.nix
  # must NOT redefine them. Each test checks the raw file content for the known
  # duplicate alias key string. Expected = false means "not present" = no duplicate.
  testPodmanNoDuplicateAliasDocker = {
    expr = lib.strings.hasInfix "\"docker\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasDockerCompose = {
    expr = lib.strings.hasInfix "\"docker-compose\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasPrun = {
    expr = lib.strings.hasInfix "\"prun\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasPexec = {
    expr = lib.strings.hasInfix "\"pexec\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasPlogs = {
    expr = lib.strings.hasInfix "\"plogs\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasContainerCleanup = {
    expr = lib.strings.hasInfix "\"container-cleanup\"" podmanRawContent;
    expected = false;
  };

  testPodmanNoDuplicateAliasContainerReset = {
    expr = lib.strings.hasInfix "\"container-reset\"" podmanRawContent;
    expected = false;
  };

  # ── opencode: RED — opencode.nix must declare opencode + bun + openspec ──────
  testOpencodeInPackages = {
    expr = builtins.elem "opencode" opencodePkgNames;
    expected = true;
  };

  testOpencodeBunInPackages = {
    expr = builtins.elem "bun" opencodePkgNames;
    expected = true;
  };

  testOpencodePluginOpenspecDeclared = {
    expr = builtins.elem "opencode-plugin-openspec" opencodeJsonConfig.plugin;
    expected = true;
  };
}
