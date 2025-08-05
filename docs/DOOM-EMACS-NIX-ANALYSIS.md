# Doom Emacs + Nix Integration Analysis

## Executive Summary

The Doom Emacs + Nix ecosystem has limited but viable declarative configuration options. Only one actively maintained, working solution exists: `nix-doom-emacs-unstraightened` by marienz.

## Available Solutions Analysis

### 1. nix-community/nix-doom-emacs ❌ BROKEN

- **Status**: Broken for over 1 year
- **Repository**: https://github.com/nix-community/nix-doom-emacs
- **Stars**: 229
- **Last Updated**: 2025-07-21
- **Issue**: Package locking mechanism conflicts with emacs-overlay
- **Official Statement**: "⚠ Broken - This project has been broken for more than a year due to Doom's excessive divergence from emacs-overlay's package set"
- **Tracking Issues**:
  - Update PR: #316
  - Tracking issue: #353

### 2. vlaci/nix-doom-emacs ❌ DEPRECATED

- **Status**: Deprecated, maintainer no longer develops it
- **Repository**: https://github.com/vlaci/nix-doom-emacs
- **Stars**: 231
- **Last Updated**: 2025-07-30
- **Issue**: Points users to nix-community version (which is broken)
- **Official Statement**: "⚠ I no longer use or develop this package. Use the nix-community mirror instead."

### 3. marienz/nix-doom-emacs-unstraightened ✅ VIABLE

- **Status**: Active, working, maintained
- **Repository**: https://github.com/marienz/nix-doom-emacs-unstraightened
- **Stars**: 102
- **Last Updated**: 2025-08-05 (very recent)
- **CI Status**: ✅ Passing
- **Platform Support**: Linux (tested), macOS (reported working)
- **Approach**: Completely avoids straight.el, uses Doom's CLI for dependency export

## Declarative Configuration Assessment

### Available Declarative Features ✅

**nix-doom-emacs-unstraightened provides:**

1. **Full Home Manager Integration**

   ```nix
   programs.doom-emacs = {
     enable = true;
     doomDir = ./doom.d;  # or external flake input
     provideEmacs = true;  # provides both doom-emacs and emacs binaries
   };
   ```

2. **Flake-based Configuration**

   - Automatic dependency management
   - Reproducible builds via flake.lock
   - Integration with emacs-overlay for latest packages

3. **Package Management**

   - All dependencies managed through Nix
   - No need for `doom sync` or manual package management
   - Conflicts with package.el eliminated

4. **Configuration Storage**
   - Doom configuration stored in Nix store
   - Matches enabled modules with available dependencies
   - Full reproducibility across machines

### Limitations ⚠️

1. **Configuration Mutability**

   - Doom config stored in Nix store (read-only)
   - Requires rebuild for configuration changes
   - No interactive package installation via Doom

2. **Profile System Changes**

   - Uses different directory structure than standard Doom
   - Cache/data/state dirs follow XDG standards instead of `$DOOMLOCALDIR`
   - Migration from existing Doom installations requires file moves

3. **Platform Limitations**
   - macOS support not covered by CI
   - Potential issues with Nix versions >2.18.x
   - `org +roam` module doesn't work (use `org +roam2`)

## Package.el Integration Analysis

### Conflict Resolution ✅

**nix-doom-emacs-unstraightened approach:**

1. **Eliminates straight.el entirely** - avoids package manager conflicts
2. **Uses Doom's native dependency export** - ensures compatibility
3. **Routes all packages through Nix** - single source of truth
4. **Prevents package drift** - locked versions via emacs-overlay

### Package Management Workflow

**Traditional Doom:**

```bash
doom sync          # Install/update packages
doom build         # Rebuild configuration
doom purge         # Clean unused packages
```

**With nix-doom-emacs-unstraightened:**

```bash
nixos-rebuild switch    # or home-manager switch
# All package management handled declaratively
```

## Comparison: Declarative vs Traditional

| Aspect                    | Traditional Doom         | nix-doom-emacs-unstraightened |
| ------------------------- | ------------------------ | ----------------------------- |
| **Package Management**    | straight.el, package.el  | Pure Nix                      |
| **Reproducibility**       | Partial (pins some deps) | Complete (all deps pinned)    |
| **Configuration Changes** | Live editing             | Rebuild required              |
| **Dependency Conflicts**  | Possible                 | Eliminated                    |
| **System Integration**    | Manual                   | Full Home Manager             |
| **Rollback Support**      | Limited                  | Full Nix generations          |

## Recommendations

### For Declarative Integration ✅ RECOMMENDED

Use `marienz/nix-doom-emacs-unstraightened`:

**Advantages:**

- Only working declarative solution
- Full Home Manager integration
- Complete reproducibility
- Active maintenance and CI
- Eliminates package management conflicts

**Trade-offs:**

- Configuration changes require rebuilds
- Different directory structure
- Less flexibility for experimentation

### Hybrid Approach Alternative

If full declarative approach is too restrictive:

1. **Base Emacs via Nix** (current setup)
2. **Manual Doom Installation** (upstream method)
3. **Selective Nix Integration** (LSP servers, tools)

**Pros:** More flexible, easier experimentation
**Cons:** Loses reproducibility benefits, potential conflicts

## Implementation Strategy

For integration with existing `home/dan/features/productivity/emacs.nix`:

### Phase 1: Evaluation

1. Test nix-doom-emacs-unstraightened in isolated environment
2. Verify compatibility with current Emacs 30.1 setup
3. Validate macOS functionality

### Phase 2: Integration

1. Add flake input to main flake.nix
2. Create doom configuration directory
3. Modify emacs.nix to use Doom integration
4. Preserve existing LSP and tool configurations

### Phase 3: Migration

1. Backup current Emacs configuration
2. Switch to Doom-based setup
3. Test all functionality
4. Document rollback procedures

## Conclusion

**Declarative Doom Emacs integration is viable but limited.** The `nix-doom-emacs-unstraightened` solution provides robust declarative configuration with full Home Manager integration, making it suitable for production use despite some workflow changes required.

The main trade-off is reduced configuration flexibility in exchange for complete reproducibility and elimination of package management conflicts.
