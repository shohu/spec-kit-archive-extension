---
description: Archive a completed Spec-Kit feature with constitution-driven intelligent merge to specs/latest/.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

**Note**: The feature slug is **optional**. If the user provides an empty command (no arguments), you MUST auto-detect the most recent feature directory. Do not ask the user to provide it unless auto-detection fails.

## GPT-5-Codex Execution Strategy

**Autonomous operation**: Leverage GPT-5-Codex's ability to work independently for extended periods (up to 7+ hours).

**Dynamic reasoning**: Allow the model to adaptively decide when to use quick responses vs. deep analysis.

**High-precision validation**: Utilize the 74.5% SWE-bench success rate for accurate implementation checks.

**Structured workflow**: Follow clear steps but enable autonomous decision-making within each step.

**Code-aware context**: Leverage deep codebase understanding for validation and merge decisions.

## Step-by-Step Execution

### Step 1: Determine Feature Slug

**Auto-detection logic**:
```bash
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root/specs"
feature_slug=$(ls -1d [0-9][0-9][0-9]-* 2>/dev/null | grep -v '^latest$' | grep -v '^archive$' | sort -r | head -n1)
```

**Manual input**: If `$ARGUMENTS` is provided and not empty, use it as `feature_slug`.

**Validation**: Check if `$repo_root/specs/$feature_slug` exists.

**Output**: "📦 Archiving feature: **{feature_slug}**"

**Checkpoint**: ✅ Feature identified

---

### Step 2: Validate Feature Directory

**Command**:
```bash
cd "$repo_root/specs/$feature_slug"
ls -la
```

**Check for required files**:
- `spec.md` (required)
- `plan.md` (recommended)
- `tasks.md` (optional)

**Checkpoint**: ✅ Feature directory validated

---

### Step 3: Check Task Completion (Informational)

**Command**:
```bash
if [ -f "$repo_root/specs/$feature_slug/tasks.md" ]; then
  grep -c '\[ \]' "$repo_root/specs/$feature_slug/tasks.md" || echo "0"
fi
```

**Output**: Report number of unchecked tasks (if any).

**Action**: Warn if tasks remain, but continue archiving.

**Checkpoint**: ✅ Tasks reviewed

---

### Step 4: Run Validation Script (Informational)

**Command**:
```bash
cd "$repo_root"
.specify/scripts/bash/archive/core/validate-implementation.sh "$feature_slug"
```

**Expected checks**:
- User stories have corresponding tests
- Plan.md mentioned files exist
- Data model entities exist in code

**Output**: Display warnings if any (non-blocking).

**Checkpoint**: ✅ Validation complete

---

### Step 5: Check Git Branch for Merge

**Detect current branch**:
```bash
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $current_branch"
```

**Check if on spec branch**:
```bash
if [[ "$current_branch" =~ ^feat/specs-[0-9]{3}- ]]; then
  echo "✅ On spec feature branch"
  echo "Merge into parent branch after archiving? (will prompt during archive)"
else
  echo "ℹ️  Not on spec feature branch, skipping merge option"
fi
```

**Checkpoint**: ✅ Branch checked

---

### Step 6: Execute Archive Script

**Command (without merge)**:
```bash
cd "$repo_root"
.specify/scripts/bash/archive/core/archive-feature.sh --json --feature "$feature_slug"
```

**Command (with merge prompt)**:
```bash
cd "$repo_root"
.specify/scripts/bash/archive/core/archive-feature.sh --json --feature "$feature_slug" --with-merge
```

**Script behavior**:
1. Merges feature specs into `specs/latest/`:
   - `spec.md`: Accumulates user stories, merges requirements by ID
   - `plan.md`: Accumulates technical context, uses latest architecture
   - `data-model.md`: Merges entities intelligently
   - `contracts/`: Syncs directory
2. Moves feature to `specs/archive/$feature_slug`
3. **With --with-merge**: Prompts for merge into parent branch, handles checkout and merge
4. Outputs JSON summary

**Error handling**: If script fails, display full error and stop.

**Checkpoint**: ✅ Archive complete

---

### Step 7: Parse Script Output

**Expected JSON structure**:
```json
{
  "archived_path": "specs/archive/XXX-feature-name/",
  "latest_path": "specs/latest/",
  "synced_items": ["spec.md", "plan.md", "data-model.md", "contracts/"],
  "warnings": [],
  "merge_performed": true,
  "merge_error": null
}
```

**Action**: Extract key information for summary.

**Checkpoint**: ✅ Output parsed

---

### Step 8: Verify Merged Files

**Commands**:
```bash
cd "$repo_root/specs/latest"
wc -l spec.md plan.md data-model.md
ls -la contracts/
```

**Output**: Show file sizes and contract count.

**If merge was performed**:
```bash
git rev-parse --abbrev-ref HEAD  # Should show parent branch
git log --oneline -1              # Show merge commit
```

**Checkpoint**: ✅ Merge verified

---

### Step 9: Generate Summary

**Format**:
```
✅ Archived feature: {feature-slug}

📦 Archive location:
   specs/archive/{feature-slug}/

📝 Merged to specs/latest/:
   - spec.md (N lines)
   - plan.md (N lines)
   - data-model.md (N lines)
   - contracts/ (N files)

🔍 Validation:
   {results or "All checks passed"}

⚠️  Warnings:
   {warnings or "None"}

🔀 Git Integration:
   {if merged: "✅ Merged into {parent-branch}, feature branch deleted"}
   {if skipped: "Merge skipped, changes ready for commit"}

📌 Next steps:
   {if merged}:
   1. Current branch: {parent-branch}
   2. Push: git push origin {parent-branch}
   3. Continue: /speckit.specify (for next feature)
   
   {if not merged}:
   1. Review: git status
   2. Stage: git add specs/archive/ specs/latest/
   3. Commit: git commit -m "feat: archive {feature-slug}"
   4. Continue: /speckit.specify (for next feature)
```

**Checkpoint**: ✅ Summary complete

---

## Error Handling

### No Feature Found
**Action**: List available features in `specs/` and ask user to specify one.

### Feature Directory Missing
**Action**: Display error and stop. Suggest checking `specs/` directory.

### Archive Script Fails
**Action**:
1. Display stderr and stdout in full
2. Check if `.specify/scripts/bash/archive/` exists
3. Suggest running install script if missing
4. Stop execution - do not proceed with partial archive

### JSON Parse Error
**Action**: Display raw output and attempt manual parsing of created files.

---

## GPT-5-Codex Best Practices

1. **Autonomous validation**: Independently verify spec-code alignment using deep codebase analysis
2. **Intelligent merge decisions**: Apply dynamic reasoning to resolve conflicts and edge cases
3. **Comprehensive testing**: Automatically check user story coverage, file existence, and entity alignment
4. **Adaptive execution**: Use quick validation for simple checks, deep analysis for complex merges
5. **Code-aware context**: Reference actual implementation when making merge decisions
6. **Proactive error recovery**: Detect and fix issues without requiring user intervention
7. **Structured reporting**: Provide detailed but concise summaries with concrete metrics

## GPT-5-Codex Advantages for This Task

- **Extended operation**: Can handle large spec merges without timeout
- **Code understanding**: Deep analysis of implementation vs. specification alignment
- **Pattern recognition**: Identifies merge conflicts and proposes intelligent resolutions
- **Validation depth**: Cross-references specs, plans, code, and tests simultaneously
