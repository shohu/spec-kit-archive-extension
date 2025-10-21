# Usage

## Basic Command

```bash
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature
```

## What It Does

1. Validates implementation vs spec
2. Merges spec files to `specs/latest/`
3. Syncs `contracts/` directory
4. Moves feature to `specs/archive/`

## Merge Strategies

### spec.md

- **User Stories**: Accumulated (all preserved)
- **Requirements (FR/NFR)**: Merged by ID (FR-001 updated if redefined)
- **Success Criteria**: Accumulated (unique)

### plan.md

- **Summary**: Latest version
- **Technical Context**: Accumulated (history preserved)
- **Architecture**: Latest version

### data-model.md

- **Entities**: Intelligently merged (same name = unified)

## Workflow

```bash
# 1. Complete feature implementation
# 2. Validate
.specify/scripts/bash/archive/core/validate-implementation.sh --feature 002-my-feature

# 3. Archive
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature

# 4. Review merged output
git diff specs/latest/

# 5. Commit
git add specs/
git commit -m "feat(spec): archive 002-my-feature"
```

## Custom Merge Rules

Edit `config/merge-rules.json`:

```json
{
  "rules": {
    "Your Section": {
      "strategy": "accumulate",
      "reason": "Why this strategy"
    }
  }
}
```

Strategies: `accumulate`, `merge_by_id`, `accumulate_unique`, `merge_entities`, `latest`

## Dry Run

```bash
# Test without changes
.specify/scripts/bash/archive/core/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output /tmp/test.md

# Review the result
diff -u specs/latest/spec.md /tmp/test.md
```

## Verification Examples

```bash
# Check user story count (should accumulate)
grep -c "^### " specs/latest/spec.md

# Check requirement IDs (should merge by ID)
grep "^- \*\*FR-" specs/latest/spec.md

# Check phases (should accumulate)
grep "^## Phase" specs/latest/tasks.md
```

## Testing

```bash
# Test all file types
for file in spec plan tasks data-model; do
  echo "=== Testing $file.md ==="
  .specify/scripts/bash/archive/core/merge-spec.sh \
    --base specs/archive/001-core/$file.md \
    --incoming specs/002-feature/$file.md \
    --output /tmp/test-$file.md
  echo "Lines: $(wc -l < /tmp/test-$file.md)"
done
```

## Troubleshooting

### Q: Merge result is different than expected

**A**: Check the following:

1. Strategy definitions in `config/merge-rules.json`
2. Exact section name matching (check for extra spaces, special characters)
3. Use dry run to test: `/tmp/test-merged-*.md`

```bash
# Dry run test
.specify/scripts/bash/archive/core/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output /tmp/test-spec.md

# Review result
diff -u specs/latest/spec.md /tmp/test-spec.md
```

### Q: Specific section disappeared

**A**: Section names might not match exactly.

```bash
# Check section names
grep "^##" specs/latest/spec.md
grep "^##" specs/002-feature/spec.md
```

### Q: Entities are duplicated

**A**: Ensure entity names in data-model.md start with uppercase letters and follow naming conventions (e.g., `Player`, `GameState`, `Resource`).

## AI Command Usage

With **Cursor IDE** or **OpenAI Codex**:

```
# Archive specific feature
/speckit.archive 002-my-feature

# Auto-detect most recent feature (recommended)
/speckit.archive
```

**Recommended Models**:
- **GPT-5** (2025): Best for autonomous validation and complex merges (74.5% SWE-bench success rate)
- **Claude Sonnet 4.5**: Excellent for parallel processing and detailed analysis

The AI will:
1. Auto-detect the feature if not specified
2. Run comprehensive validation checks (using deep code analysis with GPT-5-Codex)
3. Execute the archive script with intelligent merge strategies
4. Show a formatted summary with concrete metrics
5. Suggest next steps (git commands, next feature planning)
