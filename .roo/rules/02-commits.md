## Git Commit Hygiene

Create commits at these mandatory points:

- Mode switch
- Subtask start and end
- After successful `nix flake check`
- After applying configuration changes (`nixos-rebuild switch` / `darwin-rebuild switch`)
- After adding or removing a host, feature module, or overlay

**Note**: For project-specific commit message format, see your project's `.roo/rules/*-commits.md`
