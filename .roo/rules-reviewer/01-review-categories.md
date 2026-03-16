# Review Categories and Code Smell Catalog

## Rule ID: REV-CAT-001

## 6 Review Categories

Check each change across these categories:

### SEC – Security
- Hardcoded Credentials, API Keys, Secrets
- SQL Injection, XSS, CSRF Vulnerabilities
- Unsafe Deserialization
- Missing Input Validation
- Unsafe Cryptography
- Missing Authentication/Authorization Checks
- **Default-Severity**: CRITICAL or HIGH

### READ – Readability
- Unclear variable/method/class names
- Missing or outdated documentation/Javadoc
- Excessive nesting (>3 levels)
- Inconsistent formatting or coding style
- Overly complex expressions
- **Default-Severity**: LOW or MEDIUM

### PERF – Performance
- N+1 Queries in database access
- Unnecessary loops or redundant calculations
- Missing indexes in DB queries
- Memory leaks, unbounded collections
- Blocking I/O in async contexts
- Inefficient algorithms (O(n²) where O(n) is possible)
- **Default-Severity**: MEDIUM or HIGH

### MAINT – Maintainability
- Duplicate code (DRY violation)
- Long methods (>30 lines)
- Large classes (>300 lines)
- Long parameter lists (>4 parameters)
- Tight coupling between modules
- God Objects / Feature Envy
- **Default-Severity**: MEDIUM

### TEST – Testing
- Missing tests for new logic
- Insufficient edge-case coverage
- Fragile tests (time-dependent, order-dependent)
- Missing assertions
- Test code duplication
- **Default-Severity**: MEDIUM

### ARCH – Architecture
- Violation of layered architecture (e.g., Controller → Repository directly)
- Circular dependencies
- Wrong package assignment
- Violation of SOLID principles
- Wrong use of design patterns
- **Default-Severity**: HIGH

## Code Smell Catalog

### Structural Smells

| Smell | Detection Criterion | Severity |
|-------|---------------------|----------|
| Long Method | >30 lines | MEDIUM |
| Large Class | >300 lines | MEDIUM |
| Long Parameter List | >4 parameters | MEDIUM |
| Duplicate Code | ≥3 lines identical code | MEDIUM |
| Deep Nesting | >3 nesting levels | MEDIUM |
| Primitive Obsession | Primitives instead of domain types for concepts | LOW |

### Semantic Smells

| Smell | Detection Criterion | Severity |
|-------|---------------------|----------|
| Feature Envy | Method uses foreign class more intensively than own | MEDIUM |
| Data Clumps | Same parameter groups in ≥3 methods | LOW |
| Shotgun Surgery | One logical change → changes in >3 files | HIGH |
| Divergent Change | One class changed for >3 different reasons | MEDIUM |
| Middle Man | Class delegates >50% of its methods | LOW |
| Inappropriate Intimacy | Class excessively accesses internals of another class | MEDIUM |

### Hygiene Smells

| Smell | Detection Criterion | Severity |
|-------|---------------------|----------|
| Dead Code | Unreachable or unused code (deadnix findings) | MEDIUM |
| Commented-Out Code | Commented code without explanation | LOW |
| Magic Numbers | Hardcoded values without named constant | LOW |
| Inconsistent Naming | Deviation from project conventions | LOW |
| TODO/FIXME without Ticket | TODO/FIXME without issue reference | LOW |

### Nix-Specific Smells

| Smell | Detection Criterion | Severity |
|-------|---------------------|----------|
| Missing module `...` | Module function signature missing `...` for forward compatibility | MEDIUM |
| Broad `with pkgs;` scope | `with pkgs;` used at module level instead of limited scope | MEDIUM |
| Hardcoded paths | Paths hardcoded instead of using option references | MEDIUM |
| Unused `let` bindings | Variables bound in `let` but never used (deadnix findings) | MEDIUM |
| Missing `nix flake check` validation | Changes not validated with `nix flake check` | HIGH |
| Missing host-specific build validation | Modified host not tested with `nixos-rebuild build` or `darwin-rebuild build` | MEDIUM |
