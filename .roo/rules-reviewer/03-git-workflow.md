# Git-based Review Workflow

## Rule ID: REV-GIT-001

## COMMIT Review Workflow

When receiving commit hashes:

### Single Commit
```bash
git show <commit-hash> --stat     # Overview of changed files
git show <commit-hash>             # Full diff
```

### Commit Range
```bash
git log --oneline <hash1>..<hash2>  # Commit overview
git diff <hash1>..<hash2> --stat    # Changed files
git diff <hash1>..<hash2>           # Full diff
```

### Multiple Individual Commits
For each commit separately:
```bash
git show <hash> --stat
git show <hash>
```

## BRANCH Review Workflow

When receiving a branch name:

### Standard Workflow (Base: main)
```bash
git log --oneline main..<branch>           # Commit overview
git diff main..<branch> --stat             # Changed files
git diff main..<branch>                    # Full diff
```

### With Explicit Base Branch
```bash
git log --oneline <base>..<branch>        # Commit overview
git diff <base>..<branch> --stat          # Changed files
git diff <base>..<branch>                 # Full diff
```

### With Large Diffs (>500 lines)
Split by files:
```bash
git diff main..<branch> --stat             # First overview
git diff main..<branch> -- path/to/file    # Then file by file
```

## FILE Review Workflow

When receiving file paths:
- Read each file with `read_file`
- Analyze the complete file content
- Check context as well (imports, dependencies)

## Focus Rules for Diff Reviews

For COMMIT and BRANCH reviews:

1. **Primary Focus**: The CHANGED lines (+ and - lines in diff)
2. **Secondary Focus**: Context around changes (method/class containing change)
3. **Do NOT Review**: Unchanged parts of file, unless directly affected by changes

## Handling Large Diffs

For diffs >1000 lines:
1. First use `--stat` for overview
2. Prioritize files by relevance (production code before tests, core logic before config)
3. Go through file by file
4. Note in report that a large diff was provided
