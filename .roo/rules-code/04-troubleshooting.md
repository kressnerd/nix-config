# Troubleshooting & Error Handling

## Error Resolution Protocol

1. **Reproduce**: `nix build` or `nixos-rebuild dry-activate` to confirm the error
2. **Read first error frame**: Focus on the first error message; ignore noise from cascading failures
3. **Common causes**: Check for missing inputs, wrong option path, missing import, unfree license
4. **Fix**: Propose targeted, minimal fix
5. **Validate**: Run `nix flake check` after fix
6. **Rollback**: If fix is unsuccessful, offer rollback path or clean disable of the change

## Common Build Errors

### Missing Input / Undefined Variable

```
error: undefined variable 'inputs'
```

**Fix**: Ensure `inputs` is passed via `specialArgs` in `flake.nix` and received in the module's function signature.

### Wrong Option Path

```
error: The option `services.foo.bar` does not exist
```

**Fix**: Query MCP or `nixos-option` to find the correct option path. Option may have been renamed or restructured.

### Unfree License

```
error: <package> has an unfree license ('unfree'), refusing to evaluate
```

**Fix**: Verify `nixpkgs.config.allowUnfree = true;` is set. For selective unfree: use `allowUnfreePredicate`.

### Missing Import

```
error: attribute 'foo' missing
```

**Fix**: Check that the module is imported in the consuming configuration. Wire import in `default.nix` or host profile.

### Hash Mismatch (Fixed-Output Derivation)

```
error: hash mismatch in fixed-output derivation
```

**Fix**: Update the hash to match the new source. Use `lib.fakeHash` temporarily to get the correct hash from the error output.

## Diagnostic Commands

| Command | Purpose |
|---------|---------|
| `nix flake check` | Validate flake syntax and evaluate all outputs |
| `nix flake show` | Display flake output structure |
| `nix build --dry-run .#<target>` | Check what would be built without building |
| `sudo nixos-rebuild dry-activate --flake .#<host>` | Dry-run activation (shows service changes) |
| `sudo nixos-rebuild test --flake .#<host>` | Activate without making it the boot default |
| `nix repl` then `:lf .` | Interactive attribute exploration |
| `nix eval .#<attr>` | Evaluate a specific attribute |
| `nix path-info -rs .#<target>` | Show closure size and dependencies |
| `nix why-depends .#<a> .#<b>` | Explain dependency chain |
| `--show-trace` | Add to any nix command for detailed error traces |
| `NIX_SHOW_STATS=1` | Show evaluation statistics |

## Service Debugging (NixOS)

```bash
# Check service status
systemctl status <unit>

# View recent logs
journalctl -u <unit> --since "5 min ago"

# Follow logs in real-time
journalctl -u <unit> -f

# List all services from a NixOS module
systemctl list-units 'nixos-*'
```

## Rollback Procedures

### NixOS Generation Rollback

```bash
# Immediate rollback to previous generation
sudo nixos-rebuild --rollback switch

# List available generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Switch to specific generation
sudo nix-env --switch-generation <N> -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Home Manager Rollback

```bash
# List generations
home-manager generations

# Activate previous generation (copy path from listing)
/nix/store/<hash>-home-manager-generation/activate
```

### macOS (nix-darwin) Rollback

```bash
# Use previous generation from /nix/var/nix/profiles/system-*-link
# Or rebuild with previous flake.lock:
git checkout HEAD~1 -- flake.lock
darwin-rebuild switch --flake .#<host>
```

### Flake Lock Rollback

```bash
# Revert a specific input update
git checkout HEAD~1 -- flake.lock
nix flake check
```

## Garbage Collection

```bash
# List generations before collecting
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Delete old generations (CAUTION: removes rollback targets)
sudo nix-collect-garbage -d

# Delete generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Optimize store
nix store optimise
```

**CRITICAL**: Warn user before garbage collection that it removes rollback generations.

## Impermanence Debugging

For hosts using impermanence (thiniel, cupix001):

- State not persisting? Check `environment.persistence."/persist"` paths
- After reboot, only paths in the persistence config survive
- Verify with: `ls /persist/system/` and `ls /persist/home/`
- Add missing paths to the impermanence module, then rebuild and reboot

## Performance Issues

### Slow Evaluation

- Check for large `import` chains or recursive overlays
- Use `nix eval --show-trace` to identify bottleneck
- Consider `builtins.trace` for debugging evaluation order

### Large Closure Size

```bash
nix path-info -rsSh .#nixosConfigurations.<host>.config.system.build.toplevel
```

- Look for unexpected dependencies
- Use `nix why-depends` to trace unwanted references
- Remove unnecessary `buildInputs` in derivations

## References (On Demand)

- Official NixOS manual and option search: https://search.nixos.org
- Home Manager option search: https://nix-community.github.io/home-manager/options.xhtml
- Nix language reference: https://nix.dev
- Community resources (Discourse, Matrix): provide only when asked
