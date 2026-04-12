# Fundamental Principles — Cross-Cutting Development Standards

## Rule ID: FUND-001

**Priority**: MANDATORY  
**Applies to**: All modes, all languages (Nix, Python), all code changes

## Principles

### 1. Test-Driven Development (TDD)

- Write tests FIRST, ONE at a time.
- Cycle: Red → Green → Refactor. No phase may be skipped.
- Each cycle covers exactly one minimal, verifiable change.
- Nix: see TEST-FIRST-001 ([`13-test-first.md`](13-test-first.md)).
- Python: see PY-TDD-001 ([`14-python-tdd.md`](14-python-tdd.md)).

### 2. Clean Code

- Code is self-documenting. Choose descriptive names for variables, functions, modules.
- No explanatory comments. Comments indicate the code is not clear enough — refactor instead.
- Allowed comments: legal headers, TODO with issue reference, `SAFETY:` annotations for non-obvious security decisions.
- Nix: minimal comments only for non-obvious expressions (see [`10-nix-senior-admin.md`](10-nix-senior-admin.md)).
- Python: docstrings on public APIs are documentation, not comments. Inline comments are prohibited.

### 3. SOLID Principles

- **Single Responsibility**: Each file, function, and module has exactly one reason to change.
  - Nix: one concern per feature module, one service per host file.
  - Python: one class per responsibility, one function per action.
- **Open/Closed**: Extend behavior via new modules or parameters, not by modifying existing ones.
  - Nix: use `lib.mkIf`, `lib.mkMerge`, overlays for extension.
  - Python: use dependency injection, strategy pattern, composition over inheritance.
- **Liskov Substitution**: Replaceable components must honor their interface contract.
  - Nix: modules must satisfy their declared option types.
  - Python: subclasses and mock objects must honor the interface of what they replace.
- **Interface Segregation**: Do not force consumers to depend on interfaces they do not use.
  - Nix: keep module options minimal; split large option sets into independent modules.
  - Python: keep function signatures focused; pass only what the function needs.
- **Dependency Inversion**: Depend on abstractions, not concrete implementations.
  - Nix: use `specialArgs`, module options, and overlays — not hardcoded paths or values.
  - Python: use injectable parameters (`auth=None`, `client=None`), not global instances.

### 4. DRY — Don't Repeat Yourself

- Every piece of knowledge has exactly one authoritative representation.
- Nix: factor shared logic into `lib/`, overlays, or reusable modules. No copy-paste between host configs.
- Python: extract shared functions into utility modules. No duplicated business logic across CLI commands.
- Documentation: use cross-references instead of duplicating content (see DOC-STD-001).

### 5. KISS — Keep It Simple

- Choose the simplest working solution.
- Nix: prefer module options over custom derivations. Prefer `mkDefault` over `mkForce`.
- Python: prefer stdlib (`argparse`, `logging`, `pathlib`) over third-party libraries when sufficient.
- No premature abstraction. Extract only when duplication is proven (Rule of Three).

### 6. YAGNI — You Aren't Gonna Need It

- Implement only what is required by current, accepted requirements.
- Do not add options, parameters, or features "for later".
- Do not create abstractions for a single use case.
- If it is not in the current task specification, do not implement it.

### 7. Security First

- Follow OWASP best practices in every implementation.
- Never commit plaintext secrets. Use sops-nix or agenix (see [`10-nix-senior-admin.md`](10-nix-senior-admin.md)).
- Credential files: `0o600` permissions. Credential directories: `0o700` permissions.
- Python: `ruff check` with `S` (bandit) rules enabled (see PY-QUAL-001). No hardcoded credentials.
- Nix: enable firewalls by default. Restrict SSH access. Validate inputs.
- Treat all external input as untrusted: API responses, user input, file contents.
- Log security-relevant events. Never log secrets or credentials.

## Enforcement

- Reviewer Mode MUST verify adherence to these principles during code review.
- Architect Mode MUST design solutions that respect these principles.
- Code Mode MUST refuse to implement solutions that violate these principles.
- Any violation is grounds for rejecting a change.

## Relationship to Other Rules

This rule establishes the foundational principles. All other rules (Nix-specific, Python-specific, mode-specific) are implementations of these principles. In case of ambiguity, these principles take precedence.
