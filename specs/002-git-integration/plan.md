# Implementation Plan: Git Branch Integration

## Summary
Add optional Git branch integration to archive workflow, enabling one-command archive and merge operations.

## Technical Context

### Previous State
Archive operation completes successfully, but developer must manually:
1. Check git status
2. Stage changes
3. Commit with appropriate message
4. Checkout parent branch
5. Merge feature branch
6. Delete feature branch (optional)

### Current Implementation
Adding `--with-merge` flag to automate branch detection, merge, and cleanup.

### Rationale
Reducing manual git operations streamlines the spec-driven development workflow and reduces the chance of forgotten merges or inconsistent commit messages.

## Architecture

### New Components

```bash
# archive-feature.sh additions
WITH_MERGE=false  # New flag
MERGE_PERFORMED=false  # New state tracking

# New functions
detect_spec_branch()
identify_parent_branch()
prompt_merge()
perform_merge()
cleanup_branch()
```

### Integration Points

```
archive-feature.sh workflow:
1. Parse arguments (including --with-merge)
2. Validate feature directory
3. Run validation checks
4. Perform archive and merge to latest/
5. Move feature to archive/
6. [NEW] If --with-merge:
   a. Detect current branch
   b. Identify parent branch
   c. Prompt for merge
   d. Perform merge if confirmed
   e. Offer branch cleanup
7. Output results (JSON or human-readable)
```

## Technical Implementation

### Branch Detection Logic

```bash
# Pattern matching for spec feature branches
if [[ "$CURRENT_BRANCH" =~ ^feat/specs-[0-9]{3}- ]]; then
  # This is a spec feature branch
fi
```

### Parent Branch Identification

```bash
# Priority order:
1. git show-branch analysis (most accurate)
2. Check for main branch
3. Check for master branch
4. Check for develop branch
5. Prompt user if none found
```

### Merge Execution

```bash
# Safe merge with checks
1. Check for uncommitted changes
2. Checkout parent branch
3. Merge with --no-ff (preserve history)
4. On conflict: abort, return to feature branch
5. On success: offer branch deletion
```

## Data Flow

### JSON Output Extension

```json
{
  "archived_path": "specs/archive/002-git-integration/",
  "latest_path": "specs/latest/",
  "synced_items": "spec.md,plan.md",
  "warnings": [],
  "merge_performed": true,           // NEW
  "merge_target_branch": "main",     // NEW
  "feature_branch_deleted": false    // NEW
}
```

## Testing Strategy

### Test Cases

1. **Normal flow**: On `feat/specs-002-test` branch, merge to `main`
2. **Uncommitted changes**: Should reject merge
3. **No parent branch**: Should prompt user
4. **Merge conflict**: Should abort and return
5. **Not on spec branch**: Should skip merge option
6. **JSON mode**: Should include merge status

### Manual Testing Script

```bash
# Setup test repository
cd /tmp
git init test-archive
cd test-archive
git checkout -b main
echo "# Test" > README.md
git add README.md
git commit -m "Initial commit"

# Create spec structure
mkdir -p .specify/memory specs/001-test
echo "Test spec" > specs/001-test/spec.md

# Create feature branch
git checkout -b feat/specs-001-test
git add specs/
git commit -m "Add test spec"

# Test archive with merge
/path/to/archive-feature.sh --feature 001-test --with-merge
# Should prompt for merge to main

# Verify
git branch  # Should show main (if merge successful)
git log --oneline -3  # Should show merge commit
```

## AI Prompt Updates

Both Cursor and Codex prompts need updates:

1. Add step: "Check Git branch and prompt for merge"
2. Update command examples with `--with-merge` flag
3. Add merge status to response format
4. Update "Next steps" based on merge status

## Performance Targets

- Branch detection: < 1 second
- Parent identification: < 2 seconds
- Merge operation: < 3 seconds
- Total overhead: < 6 seconds

## Security Considerations

- Never force push
- Never use `git reset --hard` on user branches
- Always confirm before destructive operations (branch deletion)
- Preserve uncommitted changes (fail if present)

## Rollback Plan

If issues are found:
1. Users can continue using archive without `--with-merge`
2. Manual merge is always an option
3. Git reflog preserves all operations

## Documentation Updates

- README.md: Add "Git Branch Integration" section
- docs/usage.md: Add "Git-Integrated Workflow"
- AI prompts: Update with merge steps
- Help text: Document --with-merge flag

## Success Metrics

- Adoption rate of `--with-merge` flag
- Reduction in manual git operations
- Zero data loss incidents
- User feedback on workflow improvement

