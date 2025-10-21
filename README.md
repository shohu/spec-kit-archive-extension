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

Successfully deployed in **Atlas Alchemy** project:
- ✅ 8 user stories (4+4) accumulated
- ✅ 9 functional requirements (FR-001~009) merged by ID
- ✅ 5 success criteria (SC-001~005) preserved
- ✅ Zero information loss across 002 feature archives

## 🚀 Quick Start

### Installation

```bash
# One-line install (recommended)
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/spec-kit-archive-extension/main/install.sh | bash

# Or manual install
git clone https://github.com/YOUR_USERNAME/spec-kit-archive-extension.git
cd spec-kit-archive-extension
./install.sh --target /path/to/your-project
```

The installer automatically sets up:
- ✅ Archive scripts in `.specify/scripts/bash/archive/`
- ✅ AI prompts for **Cursor** (`.cursor/prompts/`) and **Codex** (`.codex/prompts/`)
- ✅ `.gitignore` rules to track prompts while ignoring other AI artifacts

### Usage

**Command Line**:
```bash
# Archive a specific feature
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature

# JSON output (for scripting)
.specify/scripts/bash/archive/core/archive-feature.sh --feature 002-my-feature --json
```

**AI Command (Cursor/Codex)**:
```
# Archive specific feature
/speckit.archive 002-my-feature

# Auto-detect most recent feature
/speckit.archive
```

Supports both **Cursor** and **Codex** AI editors out of the box.

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

**Atlas Alchemy** (Strategy/Simulation Game):

Before archiving:
- `specs/001-core-game-architecture/` (157 lines)
- `specs/002-core-loop-synergy/` (126 lines)

After archiving with intelligent merge:
- `specs/latest/spec.md` (291 lines) ✅
  - 8 user stories (complete coverage)
  - 9 functional requirements (no duplicates)
  - 5 success criteria (comprehensive metrics)
- Information loss: **0 items**

## 🛠 Advanced Features

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
- [Contributing](CONTRIBUTING.md)

## 🗺 Roadmap

### Current (v0.1.0)
- ✅ Core merge functionality
- ✅ Constitution-driven strategies
- ✅ Implementation validation
- ✅ Atlas Alchemy production use

### Planned (v0.2.0)
- [ ] Remote installation support
- [ ] Multiple constitution profiles
- [ ] Merge conflict resolution UI
- [ ] GitHub Actions integration

### Future (v1.0.0)
- [ ] Integration into spec-kit core
- [ ] Official `/speckit.archive` command
- [ ] Community-driven merge strategies

## 🤝 Contributing

We welcome contributions! This extension is being developed with the goal of eventual integration into [spec-kit](https://github.com/context7-labs/spec-kit) core.

**How to contribute**:
1. Test in your projects and report issues
2. Suggest merge strategies for your use cases
3. Improve documentation
4. Share your constitution.md examples

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- **Spec-Kit Team** for the excellent specification-driven development framework
- **Atlas Alchemy Project** for being the proving ground
- **Community Contributors** for feedback and suggestions

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/spec-kit-archive-extension/discussions)
- **Spec-Kit Community**: [context7-labs/spec-kit](https://github.com/context7-labs/spec-kit)

---

**Note**: This extension is an independent project and is not officially affiliated with spec-kit. We are developing it with the goal of proposing integration into the official spec-kit toolkit.

