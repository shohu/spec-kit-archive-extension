---
description: Archive a completed Spec-Kit feature with constitution-driven intelligent merge to specs/latest/.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Note**: The feature slug is **optional**. If the user provides an empty command (no arguments), you MUST auto-detect the most recent feature directory. Do not ask the user to provide it unless auto-detection fails.

## Claude Code Execution Strategy

**Parallel tool execution**: Leverage Claude Code's ability to call multiple tools simultaneously for validation and file reads.

**Native tool usage**: Use Read, Glob, Grep, and Bash tools for optimal performance.

**Error recovery**: If bash scripts fail, fall back to manual parsing using file tools.

**Context retention**: Maintain all validation results and warnings across execution steps.

**Note**: This command is designed to work alongside spec-kit's `/specify` command. After archiving, use the provided hooks to avoid feature number conflicts when creating new features (see "Integration with /specify" section below).

## Outline

1. **Determine feature slug** (auto-detection if not provided)
   - Start in repo root: `git rev-parse --show-toplevel`
   - Parse user input: trim whitespace from `$ARGUMENTS`
   - **If empty or $ARGUMENTS is literally "$ARGUMENTS"**, auto-detect the most recent feature:
     ```bash
     cd "$repo_root/specs" && ls -1d [0-9][0-9][0-9]-* 2>/dev/null | \
       grep -v '^latest$' | grep -v '^archive$' | sort -r | head -n1
     ```
   - If still no slug found → Use Glob tool to enumerate `specs/` and ERROR "No feature directories found"
   - Output for confirmation: "📦 Archiving feature: **{feature_slug}**"

2. **Resolve and validate paths** (use parallel reads where possible)
   - Feature directory: `$repo_root/specs/$feature_slug`
   - If directory missing → ERROR "Feature directory not found"
   - **Parallel validation**: Use Read tool on `spec.md`, `plan.md`, `tasks.md` simultaneously to check completeness

3. **Pre-flight checks (informational)**
   - **Tasks check**: Load `tasks.md` (if present) and detect any unchecked items `[ ]`
     - Use Read tool for reliable parsing
     - If items remain, warn user but continue (archiving may proceed if intentional)
   - **Implementation validation**: Run `.specify/scripts/bash/archive/core/validate-implementation.sh`
     - Use Bash tool with proper error handling
     - Checks if spec.md user stories have tests
     - Checks if plan.md mentioned files exist
     - Checks if data-model.md entities exist in code
     - Warnings are informational only, do not block archiving
   - **If validation script fails**: Fall back to manual Grep-based checks

4. **Check Git branch and prompt for merge**
   - Detect current branch: `git rev-parse --abbrev-ref HEAD`
   - If on a spec branch (pattern: `feat/specs-XXX-*`):
     - Ask user: "🔀 Archive completed. Merge into parent branch after archiving? (y/N)"
     - If yes, add `--with-merge` flag to archive command
   - If not on spec branch or user declines, proceed without merge flag

5. **Run archive script**
   - Command (bash):
     ```bash
     cd "$repo_root" && .specify/scripts/bash/archive/core/archive-feature.sh --json --feature "$feature_slug" [--with-merge]
     ```
   - Use Bash tool with `description` explaining the merge operation
   - Run **exactly once** per invocation
   - **With --with-merge flag**: Script will prompt for merge confirmation and handle branch operations
   - The script performs:
     - **Intelligent merge** using constitution-driven strategies:
       - `spec.md`: Accumulates user stories, merges requirements by ID
       - `plan.md`: Accumulates technical context and risks, uses latest architecture
       - `data-model.md`: Merges entities intelligently
       - `quickstart.md`, `research.md`: Simple updates
     - **Note**: `tasks.md` is NOT synced (tasks are completed at archive time)
     - Syncs `contracts/` directory
     - Moves feature to `specs/archive/$feature_slug`
   - **Error handling**: If command fails:
     1. Capture and display stderr/stdout in full
     2. Check if partial merge occurred (inspect `specs/latest/`)
     3. Offer to retry or manual intervention steps
     - Do NOT silently fail - always surface errors to user

6. **Parse JSON output**
   - Expect keys: `archived_path`, `latest_path`, `synced_items`, `warnings`, `merge_performed` (if --with-merge used)
   - Use absolute paths
   - **If JSON parsing fails**: Fall back to reading output files directly with Read tool

7. **Post-archive verification** (parallel reads)
   - Read merged `specs/latest/spec.md` to count user stories
   - Read merged `specs/latest/plan.md` to verify technical sections
   - Read merged `specs/latest/data-model.md` to count entities
   - Use Glob to list `specs/latest/contracts/` directory contents
   - **Summarize changes** with concrete numbers and file paths

8. **Summarize results**
   - Show archived location: `specs/archive/$feature_slug/`
   - List merged files in `specs/latest/`:
     - `spec.md` (user stories accumulated, requirements merged by ID)
     - `plan.md` (technical info merged)
     - `data-model.md` (entities merged)
     - `contracts/` (synced)
   - Mention validation results if any
   - Note any remaining unchecked tasks (informational)
   - **If merge was performed**: Show merge result (branch name, status)

9. **Next steps**
   - **If merged**: Branch is now on parent, ready for push
   - **If not merged**:
     - Recommend: `git status` to review changes
     - Recommend: `git add specs/archive/ specs/latest/` to stage changes
   - Suggest: Create next feature or review merged specs

## Response Format

Start with feature detection confirmation (if auto-detected):
```
📦 Auto-detected feature: <feature-slug>
```

Then show the main result:
```
✅ Archived feature: <feature slug>

📦 Archive location:
   specs/archive/<feature-slug>/

📝 Merged to specs/latest/:
   - spec.md (N user stories, M requirements)
   - plan.md (technical context updated)
   - data-model.md (N entities)
   - contracts/ (synced)

🔍 Validation:
   <validation results or "All checks passed">

⚠️  Warnings:
   <if any outstanding tasks or validation warnings, or "None">

🔀 Git Integration:
   <if merge was performed: "✅ Merged into <parent-branch>, branch deleted">
   <if merge was skipped: "Merge skipped, changes staged for commit">

📌 Next steps:
   <if merged>:
   1. Current branch: <parent-branch>
   2. Push: git push origin <parent-branch>
   3. Continue with next feature

   <if not merged>:
   1. Review: git status
   2. Stage: git add specs/archive/ specs/latest/
   3. Commit: git commit -m "feat: archive <feature-slug>"
   4. Continue with next feature
```

**Special cases**:
- If no features found: Use Glob to enumerate specs/ and ask user to create one
- If multiple recent features: Show list and ask which one to archive
- If archive script fails: Report the error with stderr/stdout and suggest fixes
- If script missing: Offer to check installation or provide manual merge steps

## Integration with /specify Command

After archiving features, the `specs/` directory may only contain `latest/` and `archive/`. When creating a new feature with spec-kit's `/specify` command, the numbering should account for archived features to avoid conflicts.

**Helper Script**: This extension provides a hook to get the next safe feature number:

```bash
# Get next available feature number (checks both specs/ and specs/archive/)
if [[ -f .specify/scripts/bash/archive/hooks/pre-specify.sh ]]; then
    source .specify/scripts/bash/archive/hooks/pre-specify.sh
    NEXT_NUMBER=$(printf "%03d" $SPECKIT_NEXT_FEATURE_NUMBER)
else
    # Fallback: only check specs/ (original behavior)
    NEXT_NUMBER=$(ls -1d specs/[0-9][0-9][0-9]-* 2>/dev/null | \
                  sed 's/.*\/\([0-9]*\)-.*/\1/' | sort -nr | head -n1)
    NEXT_NUMBER=$(printf "%03d" $((10#$NEXT_NUMBER + 1)))
fi
```

**Validation**: Before creating a new feature, validate the number:

```bash
# Check for conflicts with archived features
.specify/scripts/bash/archive/core/check-feature-conflict.sh $NEXT_NUMBER
```

**Design Note**: This is an opt-in helper that does not modify spec-kit core. It works with any spec-kit version and can be safely ignored if not needed.

## Claude Code Best Practices

1. **Use native tools**: Prefer Read, Glob, Grep over Bash commands for file operations
2. **Parallel operations**: When reading multiple files for verification, call all Read tools in parallel
3. **Error resilience**: If bash script fails, attempt manual parsing and merging using file tools
4. **Verbose output**: Provide detailed explanations of each merge decision
5. **Context awareness**: Reference previous validation results when summarizing
