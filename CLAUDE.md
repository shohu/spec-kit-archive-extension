# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**spec-kit-archive-extension** is a constitution-driven intelligent archiving system for Spec-Kit projects. It merges completed feature specifications into a unified `specs/latest/` directory using intelligent, principle-based merge strategies.

### Core Concept

When a feature is complete, this system:
1. Moves `specs/NNN-feature/` to `specs/archive/NNN-feature/`
2. Intelligently merges specification files into `specs/latest/` based on section-specific strategies
3. Preserves all critical information (user stories, requirements, success criteria) with zero information loss

## Development Commands

### Testing

```bash
# Run the full test suite (dry-run mode)
./test-archive.sh

# Test with a specific feature directory
./core/archive-feature.sh --feature 001-example --json

# Validate implementation alignment
./core/validate-implementation.sh --feature 001-example
```

### Installation Testing

```bash
# Test installation to a sample project
./install.sh --target /path/to/test-project

# Verify installation
ls -la /path/to/test-project/.specify/scripts/bash/archive/
```

### Manual Merge Testing

```bash
# Test merge logic independently
./core/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output /tmp/test-output.md
```

## Architecture

### Core Components

**1. Archive Entry Point** (`core/archive-feature.sh`)
- Orchestrates the entire archiving process
- Validates feature completeness (optional, informational)
- Calls merge scripts for each specification file
- Handles Git branch integration with `--with-merge` flag
- Moves archived feature to `specs/archive/`

**2. Intelligent Merge Engine** (`core/merge-spec.sh`)
- Parses Markdown files into sections using AWK (`core/parse-markdown-sections.awk`)
- Applies section-specific merge strategies from `config/merge-rules.json`
- Supports 6 merge strategies (see below)
- Constitution-aware merging

**3. Implementation Validator** (`core/validate-implementation.sh`)
- Checks if P1 user stories have corresponding tests
- Validates that files mentioned in `plan.md` exist
- Verifies entities in `data-model.md` exist in source code
- Informational only - does not block archiving

### Merge Strategies

Defined in `config/merge-rules.json`:

| Strategy | Behavior | Use Case |
|----------|----------|----------|
| `accumulate` | Concatenates base + incoming | User stories, technical context, risks |
| `merge_by_id` | Merges by ID (FR-001, NFR-002), latest wins | Requirements, acceptance criteria |
| `accumulate_unique` | Removes duplicates while accumulating | Success criteria (SC-001, etc.) |
| `merge_entities` | Smart entity merging for data models | Entity definitions in `data-model.md` |
| `latest` | Uses incoming only | Architecture diagrams, latest structure |
| `latest_with_context` | Uses latest but preserves principle references | Background sections |

### File Structure

```
.
├── core/
│   ├── archive-feature.sh          # Main archiving script
│   ├── merge-spec.sh               # Intelligent merge engine
│   ├── validate-implementation.sh  # Spec validation
│   └── parse-markdown-sections.awk # Markdown parser
├── config/
│   └── merge-rules.json            # Section merge strategies
├── install.sh                      # Installation script
├── .cursor/commands/
│   └── speckit.archive.md         # Cursor IDE integration
└── .codex/prompts/
    └── speckit.archive.md         # OpenAI Codex integration
```

## Key Design Patterns

### Constitution-Driven Merging

The merge strategy for each section reflects project principles:
- User stories **accumulate** because each represents independent value
- Requirements **merge by ID** because they're principle-based and ID-managed
- Architecture uses **latest** because it reflects current design decisions

### Zero Information Loss

Critical information is never discarded:
- User stories from all features are preserved
- Requirements are merged by ID (FR-001, NFR-002, etc.)
- Success criteria accumulate unique items
- Archived features remain in `specs/archive/` for reference

### Section-Based Parsing

Markdown files are parsed into discrete sections (by heading level):
```
## User Stories        -> Section "User Stories"
### Story 1            -> Content within "User Stories"
## Requirements        -> Section "Requirements"
```

Each section is processed independently with its specific merge strategy.

## Git Integration

The `--with-merge` flag enables Git workflow automation:

1. Detects if current branch matches `feat/specs-NNN-*` pattern
2. Identifies parent branch (main/master/develop)
3. After archiving, prompts: "Merge into parent branch?"
4. If yes: performs `git merge --no-ff` and optionally deletes feature branch

This streamlines the workflow from feature completion to integration.

## Installation System

The `install.sh` script sets up the archive system in target projects:

1. **Copies core scripts** to `.specify/scripts/bash/archive/`
2. **Installs AI commands** to `.cursor/commands/` and `.codex/prompts/`
3. **Configures .gitignore** with whitelist approach:
   - Tracks: `core/`, `config/`, AI commands
   - Ignores: README, tests, examples, docs (project-specific)
4. **Validates constitution.md** exists (warns if missing)

### Whitelist .gitignore Strategy

```gitignore
# Ignore everything in archive/
.specify/scripts/bash/archive/*

# Except core functionality and configuration
!.specify/scripts/bash/archive/core/
!.specify/scripts/bash/archive/config/
```

**Rationale**: Core scripts are dependencies (like npm packages), documentation/tests are dev-only.

## Working with Specifications

### Spec File Types

| File | Content | Merge Strategy |
|------|---------|----------------|
| `spec.md` | User stories, requirements, success criteria | Mixed (accumulate stories, merge requirements by ID) |
| `plan.md` | Architecture, technical context, risks | Mixed (latest architecture, accumulate context/risks) |
| `data-model.md` | Entity definitions | Smart entity merging |
| `tasks.md` | Implementation checklist | **Not synced** (tasks completed at archive time) |
| `contracts/` | API contracts, schemas | Direct sync (rsync) |

### Expected Project Structure

```
target-project/
├── .specify/
│   ├── memory/
│   │   └── constitution.md      # Project principles (required)
│   └── scripts/bash/archive/    # Installed archive system
├── specs/
│   ├── 001-feature/              # Feature to archive
│   ├── 002-feature/              # Another feature
│   ├── latest/                   # Merged specifications
│   └── archive/                  # Archived features
└── src/                          # Implementation
```

## AI Integration Notes

The system is designed for both **Cursor IDE** (multi-model) and **OpenAI Codex** (GPT-5):

- **Parallel tool execution**: AI can read multiple files simultaneously for validation
- **Auto-detection**: AI can auto-detect the most recent feature to archive
- **Error recovery**: If bash scripts fail, AI can fall back to manual file parsing
- **Validation**: AI should verify merge results by counting user stories, requirements, etc.

The `/speckit.archive` command provides a complete workflow with validation, merge, and Git integration.

## Important Constraints

1. **tasks.md is never synced** - Tasks are completed at archive time, so historical tasks are not relevant
2. **Validation is informational** - Missing tests or files generate warnings but don't block archiving
3. **Constitution.md is optional** - The system works without it, but merge strategies are optimized when principles are defined
4. **Merge strategies are configurable** - Custom rules can be added to `config/merge-rules.json`

## Common Workflows

### Adding a New Merge Strategy

1. Edit `config/merge-rules.json`:
   ```json
   {
     "rules": {
       "New Section Name": {
         "strategy": "accumulate",
         "reason": "Explanation of why this strategy fits"
       }
     }
   }
   ```

2. If creating a new strategy type, implement in `core/merge-spec.sh` in the `merge_single_section()` function

### Testing Changes to Merge Logic

1. Create test fixtures in `specs/001-test/` and `specs/002-test/`
2. Run: `./core/merge-spec.sh --base specs/001-test/spec.md --incoming specs/002-test/spec.md --output /tmp/result.md`
3. Inspect `/tmp/result.md` to verify merge behavior
4. Test full archive: `./core/archive-feature.sh --feature 002-test --json`

### Debugging Merge Issues

1. Check parsed sections: Add debug output in `parse-markdown-sections.awk`
2. Verify merge rules: `cat config/merge-rules.json | jq '.rules["Section Name"]'`
3. Test section extraction: Run AWK parser independently
4. Compare expected vs actual: `diff -u expected.md actual.md`
