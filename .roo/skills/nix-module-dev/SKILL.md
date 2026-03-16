# Skill: Nix Module Development

**Applies to**: architect, code, debug
**Trigger**: Creating custom modules, overlays, derivations, or modifying flake inputs

## Scope

Deep expertise in the Nix language, module system, overlay mechanics, and derivation authoring. This skill extends the patterns in `.roo/rules/12-nix-patterns.md` with production-depth knowledge.

## Prerequisites (from existing rules)

- Repository conventions: `.roo/rules/11-repository-conventions.md`
- Basic patterns: `.roo/rules/12-nix-patterns.md`
- Persona/philosophy: `.roo/rules/10-nix-senior-admin.md`

---

## 1. Nix Language Deep Dive

### Type System

| Type | Examples | Notes |
|------|----------|-------|
| String | `"hello"`, `''multi-line''` | String interpolation: `"${expr}"` |
| Integer | `42`, `-1` | No floats in Nix |
| Bool | `true`, `false` | |
| Path | `./file.nix`, `/absolute` | Auto-resolved relative to file location |
| Null | `null` | |
| List | `[ 1 2 3 ]` | Heterogeneous, space-separated |
| Attribute set | `{ a = 1; }` | Key-value, semicolons required |
| Function | `x: x + 1`, `{ a, b }: a + b` | Single argument, destructured |

### Key Builtins

| Function | Purpose | Example |
|----------|---------|---------|
| `builtins.map` | Transform list | `map (x: x * 2) [ 1 2 3 ]` |
| `builtins.filter` | Filter list | `filter (x: x > 2) [ 1 2 3 ]` |
| `builtins.elem` | List membership | `elem "a" [ "a" "b" ]` |
| `builtins.attrNames` | Attribute keys | `attrNames { a = 1; b = 2; }` |
| `builtins.hasAttr` | Key existence | `hasAttr "a" { a = 1; }` |
| `builtins.readFile` | Read file contents | `readFile ./file.txt` |
| `builtins.toJSON` | Serialize to JSON | `toJSON { a = 1; }` |
| `builtins.fromJSON` | Parse JSON | `fromJSON ''"{"a":1}"''` |
| `builtins.fetchurl` | Fetch URL (impure) | Prefer flake inputs |
| `builtins.trace` | Debug print | `trace "debug: ${toString x}" x` |

### Key `lib` Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `lib.mkIf` | Conditional config | `mkIf cfg.enable { ... }` |
| `lib.mkMerge` | Merge config sets | `mkMerge [ set1 set2 ]` |
| `lib.mkDefault` | Overridable default | `mkDefault 8080` |
| `lib.mkForce` | Force override | `mkForce true` |
| `lib.mkOption` | Define option | `mkOption { type = ...; }` |
| `lib.mkEnableOption` | Bool enable option | `mkEnableOption "feature"` |
| `lib.mkPackageOption` | Package option | `mkPackageOption pkgs "vim" {}` |
| `lib.optional` | Conditional singleton | `optional isDarwin pkgs.darwin.apple_sdk` |
| `lib.optionals` | Conditional list | `optionals isLinux [ pkgs.a pkgs.b ]` |
| `lib.optionalString` | Conditional string | `optionalString isDarwin "-framework"` |
| `lib.optionalAttrs` | Conditional attrs | `optionalAttrs isDarwin { a = 1; }` |
| `lib.filterAttrs` | Filter attr set | `filterAttrs (n: v: v != null) set` |
| `lib.mapAttrs` | Transform attr set | `mapAttrs (n: v: v + 1) set` |
| `lib.recursiveUpdate` | Deep merge | `recursiveUpdate defaults overrides` |
| `lib.strings.concatStringsSep` | Join strings | `concatStringsSep "," [ "a" "b" ]` |
| `lib.lists.flatten` | Flatten nested lists | `flatten [ [ 1 2 ] [ 3 ] ]` |
| `lib.attrsets.genAttrs` | Generate attrs | `genAttrs [ "a" "b" ] (n: n)` |

### Pattern: Recursive Attribute Sets

```nix
# rec allows self-reference
rec {
  a = 1;
  b = a + 1;  # b = 2
}

# Preferred: let-in for clarity
let a = 1;
in { inherit a; b = a + 1; }
```

### Pattern: Function Composition

```nix
# Pipe-like composition using let
let
  data = fetchData src;
  parsed = parseConfig data;
  validated = validate parsed;
in validated

# Avoid deeply nested function calls
# BAD: validate (parseConfig (fetchData src))
```

---

## 2. Module System Architecture

### Module Structure

```nix
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.my.namespace;
in
{
  # 1. Option declarations
  options.my.namespace = {
    enable = mkEnableOption "my feature";
    
    setting = mkOption {
      type = types.str;
      default = "value";
      description = "Description of setting";
      example = "example-value";
    };
    
    listSetting = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of strings";
    };
    
    submodule = mkOption {
      type = types.submodule {
        options = {
          nested = mkOption {
            type = types.int;
            default = 42;
          };
        };
      };
      default = {};
    };
  };
  
  # 2. Configuration implementation
  config = mkIf cfg.enable {
    # Use cfg.setting, cfg.listSetting, etc.
  };
}
```

### Option Type Reference

| Type | Description | Example Values |
|------|-------------|----------------|
| `types.bool` | Boolean | `true`, `false` |
| `types.int` | Integer | `42` |
| `types.str` | String | `"hello"` |
| `types.path` | Path | `./file` |
| `types.port` | Port number (0-65535) | `8080` |
| `types.package` | Nix package | `pkgs.vim` |
| `types.enum` | Enumeration | `types.enum [ "a" "b" ]` |
| `types.listOf T` | List of type | `types.listOf types.str` |
| `types.attrsOf T` | Attr set of type | `types.attrsOf types.int` |
| `types.nullOr T` | Nullable type | `types.nullOr types.str` |
| `types.either T U` | Union type | `types.either types.str types.int` |
| `types.submodule` | Nested module | See submodule pattern above |
| `types.oneOf` | One of types | `types.oneOf [ types.str types.int ]` |
| `types.anything` | Any value | Use sparingly |
| `types.lines` | Multi-line string | Config file content |
| `types.commas` | Comma-separated | Value lists |

### Module Priority System

```
(lowest priority)
mkOptionDefault  →  mkDefault  →  (no wrapper)  →  mkOverride 50  →  mkForce
     1500              1000            100                50             50
(highest priority)
```

### Module Evaluation Order

1. All `imports` are recursively resolved
2. All `options` declarations are merged
3. All `config` values are merged using priority
4. Assertions and warnings are evaluated
5. Final configuration is produced

### Anti-patterns

- **Circular imports**: Never create A imports B imports A chains
- **Option mutation**: Never `config.x = config.x // { y = z; }` — use `mkMerge`
- **Missing `...`**: Always include `...` in function signature for forward compatibility
- **Global `with`**: Avoid `with pkgs;` at module level — limits attribute resolution

---

## 3. Overlay Mechanics

### Overlay Function Signature

```nix
# final = the final, fully resolved package set
# prev = the package set BEFORE this overlay
final: prev: {
  myPackage = prev.myPackage.override {
    someFlag = true;
  };
}
```

### Override vs Override-Attrs

```nix
# override: change function arguments (build inputs)
prev.package.override {
  python3 = prev.python311;
}

# overrideAttrs: change derivation attributes
prev.package.overrideAttrs (oldAttrs: {
  src = final.fetchFromGitHub { ... };
  patches = oldAttrs.patches ++ [ ./fix.patch ];
  buildInputs = oldAttrs.buildInputs ++ [ prev.libfoo ];
})
```

### Overlay Composition (this repo)

```nix
# overlays/default.nix
final: prev:
let
  vscodeExts = import ./vscode-extensions final prev;
in
  vscodeExts // {
    # additional overrides
  }
```

### When to Use Overlays

| Use Case | Approach |
|----------|----------|
| Modify package flags | `override` |
| Change source/patches | `overrideAttrs` |
| Add new package | Add to overlay set |
| Version pin | `overrideAttrs` with specific `src` |
| Cross-compile | `pkgsCross` overlay |

---

## 4. Derivation Authoring

### Minimal Derivation

```nix
{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "user";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-AAAA...";
  };

  nativeBuildInputs = [ ];  # Build-time tools (cmake, pkg-config)
  buildInputs = [ ];        # Libraries linked against

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp my-tool $out/bin/
    runHook postInstall
  '';

  meta = with lib; {
    description = "My tool description";
    homepage = "https://example.com";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
```

### Fetcher Reference

| Fetcher | Use Case |
|---------|----------|
| `fetchFromGitHub` | GitHub repositories |
| `fetchFromGitLab` | GitLab repositories |
| `fetchurl` | Direct URL downloads |
| `fetchzip` | Archives (auto-extracts) |
| `fetchgit` | Generic git repos |
| `fetchpatch` | Apply patches from URLs |

### Hash Calculation

```bash
# Get hash for new source
nix-prefetch-url --unpack https://github.com/user/repo/archive/v1.0.0.tar.gz

# Or use SRI hash (preferred)
nix hash to-sri --type sha256 $(nix-prefetch-url --unpack URL)

# Or use fake hash and let Nix tell you the correct one
# Set hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
# Build will fail with correct hash
```

---

## 5. Flake Input Management

### Adding a New Input

```nix
# flake.nix
inputs = {
  new-input = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";  # Pin to our nixpkgs
  };
};
```

### Input Follows Strategy

Always pin transitive `nixpkgs` to avoid duplicate nixpkgs evaluations:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
  sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  disko.inputs.nixpkgs.follows = "nixpkgs";
};
```

### Lock File Operations

```bash
# Update all inputs
nix flake update

# Update single input
nix flake lock --update-input nixpkgs

# Show current input revisions
nix flake metadata
```

---

## 6. Debugging Nix Expressions

### `builtins.trace`

```nix
# Print value during evaluation
builtins.trace "myVar = ${toString myVar}" myVar

# Deep trace (print attribute set)
builtins.trace (builtins.toJSON myAttrSet) result
```

### `nix repl`

```bash
nix repl
:lf .                    # Load current flake
:p config.services.nginx # Print evaluated value
:t pkgs.vim              # Show type
:doc lib.mkIf            # Show documentation
```

### Common Debugging Commands

```bash
# Evaluate and print
nix eval .#nixosConfigurations.<host>.config.services.nginx.enable

# Show build log
nix log .#<package>

# Build with verbose output
nix build .#<target> -L

# Show derivation
nix show-derivation .#<target>
```

## MCP Integration

Always query the nixos MCP server before guessing option paths:
- `nixos_search` — Find NixOS options/packages
- `home_manager_search` — Find Home Manager options
- `darwin_search` — Find nix-darwin options
- `nixos_info` — Get detailed option information
