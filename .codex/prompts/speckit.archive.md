---
description: Archive a completed Spec-Kit feature with constitution-driven intelligent merge to specs/latest/.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Note**: The feature slug is **optional**. If the user provides an empty command (no arguments), you MUST auto-detect the most recent feature directory. Do not ask the user to provide it unless auto-detection fails.

## Outline

1. **Determine feature slug** (auto-detection if not provided)
   - Start in repo root: `repo_root=$(git rev-parse --show-toplevel)`
   - Parse user input: `feature_slug=$(echo "$ARGUMENTS" | xargs | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')`
   - **If empty or $ARGUMENTS is literally "$ARGUMENTS"**, auto-detect the most recent feature:
     ```bash
     feature_slug=$(cd "$repo_root/specs" && ls -1d [0-9][0-9][0-9]-* 2>/dev/null | \
       grep -v '^latest$' | grep -v '^archive$' | sort -r | head -n1)
     ```
   - If still no slug found → List available features in `specs/` and ERROR "No feature directories found"
   - Output for confirmation: "📦 Archiving feature: **{feature_slug}**"

2. **Resolve paths**
   - Feature directory: `$repo_root/specs/$feature_slug`
   - If directory missing → ERROR "Feature directory not found"

3. **Pre-flight checks (informational)**
   - **Tasks check**: Load `tasks.md` (if present) and detect any unchecked items `[ ]`
     - If items remain, warn user but continue (archiving may proceed if intentional)
   - **Implementation validation**: Run `.specify/scripts/bash/archive/core/validate-implementation.sh`
     - Checks if spec.md user stories have tests
     - Checks if plan.md mentioned files exist
     - Checks if data-model.md entities exist in code
     - Warnings are informational only, do not block archiving

4. **Run archive script**
   - Command (bash):\
     `(cd "$repo_root" && .specify/scripts/bash/archive/core/archive-feature.sh --json --feature "$feature_slug")`
   - Run **exactly once** per invocation
   - The script performs:
     - **Intelligent merge** using constitution-driven strategies:
       - `spec.md`: Accumulates user stories, merges requirements by ID
       - `plan.md`: Accumulates technical context and risks, uses latest architecture
       - `data-model.md`: Merges entities intelligently
       - `quickstart.md`, `research.md`: Simple updates
     - **Note**: `tasks.md` is NOT synced (tasks are completed at archive time)
     - Syncs `contracts/` directory
     - Moves feature to `specs/archive/$feature_slug`
   - If command fails, surface stderr/stdout and stop

5. **Parse JSON output**
   - Expect keys: `archived_path`, `latest_path`, `synced_items`, `warnings`
   - Use absolute paths

6. **Summarize results**
   - Show archived location: `specs/archive/$feature_slug/`
   - List merged files in `specs/latest/`:
     - `spec.md` (user stories accumulated, requirements merged by ID)
     - `plan.md` (technical info merged)
     - `data-model.md` (entities merged)
     - `contracts/` (synced)
   - Mention validation results if any
   - Note any remaining unchecked tasks (informational)

7. **Next steps**
   - Recommend: `git status` to review changes
   - Recommend: `git add specs/archive/ specs/latest/` to stage changes
   - Suggest: Create next feature with `/speckit.specify` or review merged specs
   - Optional: Run `/speckit.plan` for the next feature

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

📌 Next steps:
   1. Review: git status
   2. Stage: git add specs/archive/ specs/latest/
   3. Commit: git commit -m "feat: archive <feature-slug>"
   4. Continue: /speckit.specify (for next feature)
```

**Special cases**:
- If no features found: List available directories in specs/ and ask user to create one
- If multiple recent features: Show list and ask which one to archive
- If archive script fails: Report the error with stderr/stdout and suggest fixes

