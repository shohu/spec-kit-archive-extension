# Installation

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/shohu/spec-kit-archive-extension/main/install.sh | bash
```

## Requirements

- Git repository
- Bash 4.0+
- `.specify/` directory (Spec-Kit project)

## Manual Install

```bash
git clone https://github.com/shohu/spec-kit-archive-extension.git
cd spec-kit-archive-extension
./install.sh --target /path/to/your-project
```

## Post-Install

Create `constitution.md` if not exists:

```bash
nano .specify/memory/constitution.md
```

Minimal template:

```markdown
# Project Constitution

## Core Principles

### Principle 1: [Your core value]
Description...

### Principle 2: [Another core value]
Description...

## Scope
- In: What this project does
- Out: What it doesn't do
```

## Verify

```bash
.specify/scripts/bash/archive/core/archive-feature.sh --help
```

Should show help message.
