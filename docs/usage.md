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
```
