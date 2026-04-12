## Git Commit Hygiene

Create commits at these mandatory points:

- Mode switch
- Subtask start and end
- After successful `nix flake check`
- After applying configuration changes (`nixos-rebuild switch` / `darwin-rebuild switch`)
- After adding or removing a host, feature module, or overlay

**Note**: For project-specific commit message format, see your project's `.roo/rules/*-commits.md`

## TDD Commit Cadence

- Commit after each completed Red-Green-Refactor cycle
- Commit message: short one-liner describing the change
- Format: `<type>(<scope>): <description>` (e.g., `feat(cupix001): enable firewall`)
- Do NOT batch multiple Red-Green cycles into a single commit
- Do NOT commit in the middle of a cycle (e.g., after Red but before Green)
