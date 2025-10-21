# Testing Guide

This repository uses **self-hosting** for testing: it contains its own spec-kit structure and test specs to validate the archive functionality.

## Test Environment Setup

The repository has been configured as a spec-kit project:

```
spec-kit-archive-extension/
├── .specify/
│   ├── memory/
│   │   └── constitution.md              # Project constitution
│   └── scripts/
│       └── bash/
│           └── archive/
│               ├── core/                 # Symlinks to core/
│               │   ├── archive-feature.sh
│               │   ├── merge-spec.sh
│               │   ├── parse-markdown-sections.awk
│               │   └── validate-implementation.sh
│               └── config/               # Symlink to config/
├── specs/
│   ├── 001-initial-setup/               # Test feature 1
│   │   ├── spec.md
│   │   ├── plan.md
│   │   └── data-model.md
│   ├── 002-git-integration/             # Test feature 2
│   │   ├── spec.md
│   │   └── plan.md
│   ├── latest/                          # Merged specs (generated)
│   └── archive/                         # Archived features (generated)
└── test-archive.sh                      # Automated test suite
```

## Running Tests

### Quick Test

```bash
./test-archive.sh
```

This will:
1. ✅ Verify directory structure
2. ✅ Verify scripts are executable and linked
3. ✅ Validate spec file structure
4. ✅ Test Markdown parser
5. ✅ Archive `001-initial-setup` feature
6. ✅ Archive `002-git-integration` feature (tests merging)
7. 🔍 Verify merge results
8. 🧹 Offer cleanup

### Manual Testing

```bash
# Archive specific feature
.specify/scripts/bash/archive/core/archive-feature.sh --feature 001-initial-setup

# Archive with JSON output
.specify/scripts/bash/archive/core/archive-feature.sh --feature 001-initial-setup --json

# Archive with Git integration (if on spec branch)
.specify/scripts/bash/archive/core/archive-feature.sh --feature 001-initial-setup --with-merge
```

### Inspect Results

```bash
# Check archive location
ls -la specs/archive/

# Check merged specs
ls -la specs/latest/

# View merged spec.md
cat specs/latest/spec.md

# View merged plan.md
cat specs/latest/plan.md
```

## Test Cases

### Test 1: Single Feature Archive
**Input**: `specs/001-initial-setup/`  
**Expected**:
- Feature moved to `specs/archive/001-initial-setup/`
- Files merged to `specs/latest/`
- `specs/latest/spec.md` contains US-001, US-002, FR-001, FR-002, FR-003

### Test 2: Second Feature Archive (Merge Test)
**Input**: `specs/002-git-integration/`  
**Expected**:
- Feature moved to `specs/archive/002-git-integration/`
- User stories accumulated: US-001, US-002, US-003, US-004
- Requirements merged: FR-001 through FR-007
- No information loss

### Test 3: Constitution Compliance
**Check**: Merge strategies follow constitution.md principles
- User stories: accumulated
- Requirements: merged by ID
- Technical context: accumulated
- Architecture: latest version

## Known Issues

### Issue: User Story Accumulation
**Status**: Under investigation  
**Description**: User stories from the first feature may not appear in `specs/latest/spec.md` after the second archive.

**Expected**: All user stories (US-001, US-002, US-003, US-004) should be present.  
**Actual**: Only user stories from the most recent feature appear.

**Workaround**: Manually inspect `specs/archive/001-initial-setup/spec.md` for original user stories.

**Investigation**: Check `merge-spec.sh` accumulate strategy implementation.

## Cleanup

After testing, restore the original state:

```bash
# Remove generated files
rm -rf specs/latest specs/archive

# Restore original feature directories (if archived)
git restore specs/
```

Or let the test script handle cleanup:
```bash
# At the end of test-archive.sh, answer 'y' to cleanup prompt
```

## Continuous Testing

### Before Commits
```bash
./test-archive.sh  # Verify no regressions
```

### After Code Changes
```bash
# Clean previous test results
rm -rf specs/latest specs/archive

# Run tests again
./test-archive.sh
```

## Dogfooding

This repository **dogfoods** its own archive system. When developing new features:

1. Create `specs/003-new-feature/` with spec.md, plan.md
2. Develop the feature
3. Test archiving: `./test-archive.sh`
4. Archive for real when ready: `.specify/scripts/bash/archive/core/archive-feature.sh --feature 003-new-feature`
5. Commit the archived specs and updated `specs/latest/`

This ensures the system is tested on real-world specifications.

## Test Coverage

Currently tested:
- ✅ Directory structure validation
- ✅ Script execution and linking
- ✅ Spec file structure
- ✅ Markdown parser
- ✅ Single feature archive
- ✅ Multi-feature merge
- ✅ JSON output format

Not yet tested:
- ⏳ Git branch integration (`--with-merge`)
- ⏳ Implementation validation
- ⏳ Custom merge rules
- ⏳ Edge cases (empty files, malformed specs)
- ⏳ Large spec files (>10,000 lines)

## Contributing Tests

To add new test cases:

1. Add test feature to `specs/`
2. Add test function to `test-archive.sh`
3. Document expected behavior here
4. Run and verify: `./test-archive.sh`

