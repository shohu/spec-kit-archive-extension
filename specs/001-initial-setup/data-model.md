# Data Model: Initial Setup

## Entities

### FeatureSpec
Represents a completed feature specification to be archived.

**Attributes**:
- `slug`: string - Feature identifier (e.g., "001-initial-setup")
- `path`: string - File system path to feature directory
- `files`: array<string> - List of spec files (spec.md, plan.md, etc.)
- `status`: enum - Status (active, archived)

**Relationships**:
- Has one Archive location
- Contains multiple SpecFile entities

### SpecFile
Individual specification document within a feature.

**Attributes**:
- `name`: string - File name (e.g., "spec.md")
- `path`: string - Full file path
- `sections`: array<Section> - Parsed Markdown sections
- `merge_strategy`: enum - How to merge (accumulate, merge_by_id, latest)

**Relationships**:
- Belongs to FeatureSpec
- Contains multiple Section entities

### Section
A Markdown section within a spec file.

**Attributes**:
- `title`: string - Section heading (e.g., "User Stories")
- `level`: int - Heading level (1-6)
- `content`: string - Section body content
- `subsections`: array<Section> - Nested sections

**Merge behavior**:
- Determined by constitution and merge-rules.json
- Examples: "User Stories" → accumulate, "Requirements" → merge_by_id

### MergeRule
Configuration for how to merge specific sections.

**Attributes**:
- `section_pattern`: string - Regex or exact match for section name
- `strategy`: enum - Merge strategy (accumulate, merge_by_id, accumulate_unique, latest, merge_entities)
- `reason`: string - Rationale from constitution

**Source**: `config/merge-rules.json`

### ValidationResult
Result of implementation validation check.

**Attributes**:
- `feature_slug`: string
- `checks`: array<Check>
- `warnings`: array<string>
- `timestamp`: datetime

**Check types**:
- User story test coverage
- File existence (from plan.md)
- Entity existence (from data-model.md)

## File System Layout

```
Repository Root/
├── .specify/
│   ├── memory/
│   │   └── constitution.md         # Project constitution
│   └── scripts/
│       └── bash/
│           └── archive/
│               ├── core/            # Core scripts
│               └── config/          # Configuration
├── specs/
│   ├── NNN-feature-name/           # Active feature
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── data-model.md
│   │   ├── tasks.md
│   │   └── contracts/
│   ├── latest/                     # Accumulated specs
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── data-model.md
│   │   └── contracts/
│   └── archive/
│       └── NNN-feature-name/       # Archived feature
```

## State Transitions

### Feature Lifecycle

```
[Active Development]
    ↓ (feature complete)
[Ready for Archive]
    ↓ (archive-feature.sh)
[Archived]
    ↓ (merged to latest/)
[Accumulated in Latest]
```

### Merge Process

```
Feature Spec → Parse Sections → Match Rules → Apply Strategy → Write to Latest
                    ↓
            Validation Check (optional)
```

## Data Integrity

### Constraints
- Feature slug must be unique
- Archive destination must not exist (prevents overwrite)
- Merge rules must reference valid strategies

### Validation Rules
- User stories must have unique identifiers (if specified)
- Requirements must follow FR-XXX or NFR-XXX pattern
- Success criteria must follow SC-XXX pattern
- Entity names must start with uppercase letter

## Examples

### Merge Strategy Mapping

| Section | Strategy | Rationale |
|---------|----------|-----------|
| User Stories | accumulate | Each story has independent value |
| Requirements | merge_by_id | ID-based, latest wins |
| Success Criteria | accumulate_unique | Multiple measurement angles |
| Technical Context | accumulate | Historical preservation |
| Architecture | latest | Current state only |
| Data Model Entities | merge_entities | Intelligent entity unification |

