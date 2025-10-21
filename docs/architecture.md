# Architecture

## Overview

Constitution-driven intelligent merge system for Spec-Kit feature archiving.

## Components

```
archive/
├── core/
│   ├── archive-feature.sh       # Main orchestrator
│   ├── merge-spec.sh            # Intelligent merge engine
│   ├── parse-markdown-sections.awk  # Section parser
│   └── validate-implementation.sh   # Implementation checker
├── config/
│   └── merge-rules.json         # Merge strategy rules
└── examples/
    └── custom-merge-rules.json  # Example customizations
```

## Flow

```
1. archive-feature.sh
   ↓
2. validate-implementation.sh (optional check)
   ↓
3. For each .md file:
   parse-markdown-sections.awk
   ↓
   merge-spec.sh (applies strategies)
   ↓
   Output to specs/latest/
   ↓
4. Move feature to specs/archive/
```

## Merge Engine

### Section Parsing (AWK)

AWK splits Markdown into sections by heading level:

```awk
## Heading  → SECTION_START|2|Heading
Content...
## Next     → SECTION_END, SECTION_START|2|Next
```

### Strategy Application

`merge-spec.sh` reads `merge-rules.json` and applies:

- **accumulate**: Both sections concatenated
- **merge_by_id**: Lines with ID patterns (FR-001) merged by ID
- **accumulate_unique**: Deduplicated accumulation
- **merge_entities**: Entity-aware merging
- **latest**: Incoming section only

### Pattern Matching

Auto-detects patterns:

- `^フェーズ[0-9]+:` → accumulate (tasks)
- `^[A-Z][a-zA-Z]+$` → merge_entities (data model)
- `^- \*\*(FR|NFR)-(\d+)` → merge_by_id (requirements)

## Why AWK?

- Fast
- Portable (available on all Unix systems)
- Perfect for line-based text processing
- No dependencies

## Extension Points

### Add New Strategy

Edit `merge-spec.sh`, add function:

```bash
merge_my_strategy() {
    local base_file="$1"
    local incoming_file="$2"
    local heading="$3"
    
    # Your logic here
}
```

Add to strategy switch in `merge_section()`.

### Add New Pattern

Edit `get_merge_strategy()` in `merge-spec.sh`:

```bash
if [[ "$section_name" =~ ^YourPattern ]]; then
    echo "your_strategy"
    return
fi
```

### Custom Validation

Add checks to `validate-implementation.sh`:

```bash
# Your validation logic
check_my_rule() {
    # ...
}
```

## Design Decisions

### Why not Python/Ruby?

- Adds dependency
- Bash/AWK are universal on Unix systems

### Why section-based merge?

- Preserves document structure
- Allows fine-grained control
- Human-readable output

### Why constitution-driven?

- Ensures consistency across projects
- Makes merge strategies explicit
- Aligns with Spec-Kit philosophy

