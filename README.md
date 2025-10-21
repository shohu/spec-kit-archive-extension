# spec-kit-archive-extension

> Constitution-driven intelligent spec archive system for Spec-Kit projects

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Spec-Kit](https://img.shields.io/badge/Spec--Kit-Extension-blue)](https://github.com/context7-labs/spec-kit)

## 🎯 Overview

**spec-kit-archive-extension** provides an intelligent archiving and merging system for completed Spec-Kit features. Built on **Constitution-driven principles**, it automatically merges specification documents while preserving information integrity.

### Key Features

- **🧭 Constitution-Driven**: Merge strategies based on your project's core principles
- **🔄 Intelligent Merging**: Section-by-section analysis with appropriate accumulation or overwrite
- **📊 Zero Information Loss**: All user stories, requirements, and success criteria are preserved
- **✅ Implementation Validation**: Automatic checks to ensure specs match actual code
- **🚀 Portable**: Self-contained system that works across projects

### Proven in Production

Successfully deployed in production projects:
- ✅ User stories accumulated across features
- ✅ Functional requirements merged by ID (FR-001~009, etc.)
- ✅ Success criteria preserved (SC-001~005, etc.)
- ✅ Zero information loss across multiple feature archives

## 🚀 Quick Start

### Installation

```bash
# One-line install (recommended)
curl -sSL https://raw.githubusercontent.com/shohu/spec-kit-archive-extension/main/install.sh | bash

# Or manual install
git clone https://github.com/shohu/spec-kit-archive-extension.git
cd spec-kit-archive-extension
./install.sh --target /path/to/your-project
```

The installer automatically sets up:
- ✅ Archive scripts in `.specify/scripts/bash/archive/`
- ✅ AI commands for **Cursor IDE** (`.cursor/commands/`) and **OpenAI Codex** (`.codex/prompts/`)
- ✅ **Smart `.gitignore` configuration** (see Git Integration below)

### Supported AI Environments

| Environment | Model | Optimized For |
|-------------|-------|---------------|
| **Cursor** | GPT-5 / Claude Sonnet 4.5 | Parallel tool execution, IDE integration |
| **Codex** | **GPT-5-Codex** (2025) | Autonomous operation, deep code analysis |

### Usage

**Command Line**:
```bash
# Archive a specific feature
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature

# Archive with Git branch merge prompt
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature --with-merge

# JSON output (for scripting)
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature --json
```

**AI Command (Cursor IDE / OpenAI Codex)**:
```
# Archive specific feature
/speckit.archive 002-my-feature

# Auto-detect most recent feature (recommended)
/speckit.archive
```

**Model Recommendations**:
- **GPT-5**: Best for autonomous validation and complex merge decisions (74.5% SWE-bench success rate)
- **Claude Sonnet 4.5**: Excellent for parallel processing and detailed analysis

## 📖 How It Works

### Constitution-Driven Merge Strategies

The system analyzes your `constitution.md` to determine optimal merge strategies for each section:

| Section Type | Strategy | Rationale |
|--------------|----------|-----------|
| User Stories | **Accumulate** | Each story represents independent value across different stages |
| Requirements (FR/NFR) | **Merge by ID** | ID-based management, latest takes precedence |
| Success Criteria (SC) | **Accumulate Unique** | Multiple measurement angles for comprehensive evaluation |
| Technical Context | **Accumulate** | Historical context preservation |
| Data Model Entities | **Smart Merge** | Entity definitions are intelligently unified |

### Architecture

```
specs/
├── 001-feature/        → Archive after completion
├── 002-feature/        → Archive after completion
├── latest/             ← Intelligent merge destination
│   ├── spec.md         (accumulated user stories)
│   ├── plan.md         (merged technical info)
│   ├── data-model.md   (unified entities)
│   └── contracts/      (synced)
└── archive/
    ├── 001-feature/    (preserved)
    └── 002-feature/    (preserved)
```

## 🔧 Configuration

### 1. Constitution Setup

Create `.specify/memory/constitution.md` with your project's core principles:

```markdown
# Project Constitution

## Core Principles

### Principle 1: Your Core Loop
Description of your main workflow or value proposition...

### Principle 2: Quality Standards
Non-functional requirements, performance targets...

### Principle 3: Scope Constraints
What's in scope, what's explicitly out of scope...
```

### 2. Custom Merge Rules

Customize merge behavior in `archive/config/merge-rules.json`:

```json
{
  "rules": {
    "Custom Section": {
      "strategy": "accumulate",
      "reason": "Your reasoning here"
    }
  }
}
```

Available strategies:
- `accumulate` - Combine both contents
- `merge_by_id` - ID-based merging (FR-001, etc.)
- `accumulate_unique` - Remove duplicates while accumulating
- `merge_entities` - Intelligent entity merging
- `latest` - Use incoming (newest) version only

## 📊 Real-World Results

**Production Project Example** (Strategy/Simulation Game):

Before archiving:
- `specs/001-core-architecture/` (157 lines)
- `specs/002-feature-enhancement/` (126 lines)

After archiving with intelligent merge:
- `specs/latest/spec.md` (291 lines) ✅
  - 8 user stories (complete coverage)
  - 9 functional requirements (no duplicates)
  - 5 success criteria (comprehensive metrics)
- Information loss: **0 items**

## 🔄 Git Integration

### What Gets Tracked?

The installer automatically configures `.gitignore` to track essential files while excluding development artifacts:

**✅ Tracked (committed to your repository)**:
- **Core scripts**: `.specify/scripts/bash/archive/core/` - Archive and merge functionality
- **Configuration**: `.specify/scripts/bash/archive/config/` - Merge rules and settings
- **AI commands**: `.cursor/commands/`, `.codex/prompts/` - Team-shared AI tools

**❌ Ignored (not committed)** - Whitelist approach:
```gitignore
# Everything else in archive/ is automatically ignored:
.specify/scripts/bash/archive/*
!.specify/scripts/bash/archive/core/      # Only track core
!.specify/scripts/bash/archive/config/    # Only track config
```

This includes: `README.md`, `LICENSE`, `TESTING.md`, `test-archive.sh`, `docs/`, `examples/`

### Why This Approach?

**Best Practice Rationale**:
1. **Core scripts = dependencies**: Like npm packages, version-controlled for consistency
2. **AI commands = team tools**: Shared across the team for standardized workflows
3. **Documentation = external**: Avoid confusion with project docs
4. **Test files = dev-only**: Not needed in production

### Manual Override

If you want different behavior, edit `.gitignore` after installation:

```bash
# To track documentation as well:
!.specify/scripts/bash/archive/README.md
!.specify/scripts/bash/archive/TESTING.md

# To track only config (ignore core scripts):
# Remove the core exception line:
# !.specify/scripts/bash/archive/core/

# To track everything (not recommended):
# Remove the whitelist pattern:
# .specify/scripts/bash/archive/*
```

## 🛠 Advanced Features

### Git Branch Integration

Automatically merge archived changes into parent branch:

```bash
# Archive and prompt for merge
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature --with-merge
```

**How it works**:
1. Detects if you're on a spec feature branch (e.g., `feat/specs-002-*`)
2. Identifies parent branch (main/master/develop)
3. Prompts: "Merge into parent branch?"
4. If yes: Merges, optionally deletes feature branch
5. If no: Continues with normal archive

**Benefits**:
- Streamlined workflow from feature completion to integration
- Automatic parent branch detection
- Safe merge with conflict detection
- Optional branch cleanup

### Implementation Validation

Automatically validates that specifications match implementation:

```bash
# Check if spec matches code
.specify/scripts/bash/archive/core/validate-implementation.sh --feature 002-my-feature
```

Validates:
- ✅ P1 user stories have corresponding tests
- ✅ Files mentioned in plan.md exist
- ✅ Entities in data-model.md exist in code

### Dry Run Testing

Test merge results before committing:

```bash
.specify/scripts/bash/archive/core/merge-spec.sh \
  --base specs/latest/spec.md \
  --incoming specs/002-feature/spec.md \
  --output /tmp/test-spec.md

# Review the result
diff -u specs/latest/spec.md /tmp/test-spec.md
```

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Usage Guide](docs/usage.md)
- [Constitution Setup](docs/constitution-guide.md)
- [Architecture Details](docs/architecture.md)

## 🗺 Roadmap

### Current (v0.1.0)
- ✅ Core merge functionality
- ✅ Constitution-driven strategies
- ✅ Implementation validation
- ✅ Production-tested

### Planned (v0.2.0)
- [ ] Remote installation support
- [ ] Multiple constitution profiles
- [ ] Merge conflict resolution UI
- [ ] GitHub Actions integration

### Future (v1.0.0)
- [ ] Potential proposal for spec-kit integration
- [ ] Enhanced AI prompts
- [ ] Community-driven merge strategies

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.


---

**Note**: This is an independent extension project and is not officially affiliated with spec-kit. It may be proposed for integration in the future, but currently operates as a standalone tool.

