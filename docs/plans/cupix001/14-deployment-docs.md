← [Back to Index](00-index.md)

## Epic 14: Deployment Documentation

**Goal**: Create deployment runbook.

**Depends on**: Epic 7, Epic 13

### Story 14.1: Deployment Guide

#### Step 14.1.1: Green — Create deployment documentation

- **File**: `docs/cupix001-deployment.md`
- **What to implement**: Pre-deployment checklist, nixos-anywhere steps, post-first-boot verification, WireGuard verification, bootstrap SSH → production SSH transition, colmena ongoing deployment, testinfra validation steps. Include blank btrfs snapshot creation command.
- **Verify**: File exists and covers all deployment phases
- **Expected**: PASS

**Note**: Documentation-only — no test-first required per rules.
