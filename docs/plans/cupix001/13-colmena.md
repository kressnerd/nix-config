← [Back to Index](00-index.md)

## Epic 13: Colmena Integration

**Goal**: Configure colmena deployment node for cupix001.

**Depends on**: Epic 1 (flake), Epic 5 (WireGuard for targetHost)

### Story 13.1: Colmena Node Configuration

#### Step 13.1.1: Red — Assert colmena hive includes cupix001

- **Test type**: unit (build check)
- **File**: N/A — verify colmena configuration evaluates
- **What to test**: `colmenaHive` in flake includes cupix001 node
- **Verify**: `nix flake check` (colmena evaluation)
- **Expected**: FAIL (cupix001 not in colmenaHive)

#### Step 13.1.2: Green — Add cupix001 to colmenaHive

- **File**: `flake.nix`
- **What to implement**: Add cupix001 node to `colmenaHive`:
  ```nix
  colmenaHive = colmena.lib.makeHive {
    meta = {
      nixpkgs = import nixpkgs { system = "x86_64-linux"; overlays = [...]; config.allowUnfree = true; };
      specialArgs = { inherit inputs outputs; };
      nodeSpecialArgs.cupix001 = {
        pkgs-unstable = (import ./lib/helpers.nix).mkPkgsUnstable {
          inherit nixpkgs-unstable;
          system = "x86_64-linux";
        };
      };
    };
    cupix001 = {
      imports = [ ./hosts/cupix001 ];
      deployment = {
        targetHost = "10.100.0.1";  # WireGuard tunnel IP — from private.nix; use placeholder until real values available
        targetUser = "dan";
        tags = [ "edge" ];
        buildOnTarget = false;  # builds happen on laptop; cupix001 has no compilers
      };
    };
  };
  ```
- **Verify**: `nix flake check`
- **Expected**: PASS
