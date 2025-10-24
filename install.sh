#!/usr/bin/env bash

set -euo pipefail

# spec-kit-archive-extension Installer
# 
# Constitution-driven intelligent spec archive system for Spec-Kit projects
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/shohu/spec-kit-archive-extension/main/install.sh | bash
#   
# Or:
#   ./install.sh --target /path/to/project
#
# Options:
#   --target PATH    Target project directory (default: current directory)
#   --help, -h       Show this help message

VERSION="0.1.0"
TARGET_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
spec-kit-archive-extension Installer

Constitution-driven intelligent spec archive system for Spec-Kit projects.

Usage:
  ./install.sh [OPTIONS]

Options:
  --target PATH    Target project directory (default: current directory)
  --help, -h       Show this help message

Example:
  # Install to current project
  ./install.sh

  # Install to specific project
  ./install.sh --target /path/to/my-project

  # Remote install (recommended)
  curl -sSL https://raw.githubusercontent.com/shohu/spec-kit-archive-extension/main/install.sh | bash

Requirements:
  - Git repository
  - Spec-Kit project structure (.specify/ directory)
  - Bash 4.0+
EOF
    exit 0
}

log() {
    echo "==> $*"
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

check_requirements() {
    local target="$1"
    
    # Check if target is a git repository
    if ! git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
        error "Target directory is not a git repository: $target"
    fi
    
    # Check if .specify directory exists
    if [[ ! -d "$target/.specify" ]]; then
        log "⚠️  .specify directory not found. Creating Spec-Kit structure..."
        mkdir -p "$target/.specify/memory"
        mkdir -p "$target/.specify/scripts/bash"
    fi
}

install_archive_system() {
    local target="$1"
    local archive_dest="$target/.specify/scripts/bash/archive"

    log "Installing archive system to: $archive_dest"

    # Copy archive directory
    if [[ -d "$SCRIPT_DIR" ]]; then
        # Local installation (from cloned repo)
        mkdir -p "$archive_dest"

        # Copy core directories
        for dir in core config hooks; do
            if [[ -d "$SCRIPT_DIR/$dir" ]]; then
                cp -r "$SCRIPT_DIR/$dir" "$archive_dest/"
                log "  ✓ Copied $dir/"
            fi
        done

        # Copy essential files (excluding development files)
        for file in "$SCRIPT_DIR"/*.{json,md} 2>/dev/null; do
            if [[ -f "$file" ]]; then
                local basename=$(basename "$file")
                # Skip README and test files
                if [[ "$basename" != "README.md" && "$basename" != "TESTING.md" ]]; then
                    cp "$file" "$archive_dest/"
                fi
            fi
        done
    else
        error "Archive source directory not found: $SCRIPT_DIR"
    fi

    log "✅ Archive system installed"
}

install_prompt() {
    local target="$1"
    
    log "Installing AI prompts..."
    
    # Install for OpenAI Codex (GPT-5-Codex optimized)
    local codex_dest="$target/.codex/prompts"
    mkdir -p "$codex_dest"
    
    if [[ -f "$SCRIPT_DIR/.codex/prompts/speckit.archive.md" ]]; then
        cp "$SCRIPT_DIR/.codex/prompts/speckit.archive.md" "$codex_dest/"
        log "✅ OpenAI Codex prompt installed (.codex/prompts/) - GPT-5-Codex optimized"
    else
        log "⚠️  Codex prompt not found"
    fi
    
    # Install for Cursor IDE (Multi-model support)
    local cursor_dest="$target/.cursor/commands"
    mkdir -p "$cursor_dest"
    
    if [[ -f "$SCRIPT_DIR/.cursor/commands/speckit.archive.md" ]]; then
        cp "$SCRIPT_DIR/.cursor/commands/speckit.archive.md" "$cursor_dest/"
        log "✅ Cursor IDE command installed (.cursor/commands/) - Multi-model support"
    else
        log "⚠️  Cursor command not found"
    fi
}

check_constitution() {
    local target="$1"
    local constitution_file="$target/.specify/memory/constitution.md"
    
    if [[ ! -f "$constitution_file" ]]; then
        log "⚠️  constitution.md not found"
        log "   The archive system requires a constitution.md file defining your project's principles."
        log "   Please create one at: $constitution_file"
        log ""
        log "   Example structure:"
        log "   - Project core principles (3-5 items)"
        log "   - Non-functional requirements"
        log "   - Scope constraints"
        log ""
        log "   See: https://github.com/shohu/spec-kit-archive-extension#constitution-setup"
    else
        log "✅ constitution.md found"
    fi
}

update_gitignore() {
    local target="$1"
    local gitignore="$target/.gitignore"
    
    if [[ -f "$gitignore" ]]; then
        # Check if spec-kit-archive rules exist
        if ! grep -q "^# Spec-Kit Archive Extension" "$gitignore" 2>/dev/null; then
            log "Adding Spec-Kit Archive Extension ignore rules to .gitignore"
            cat >> "$gitignore" <<'EOF'

# Spec-Kit Archive Extension
# Track: core scripts, config, AI commands
# Ignore: documentation, test files, meta files

# AI commands (track for team collaboration)
.codex/*
!.codex/prompts/
.codex/prompts/*
!.codex/prompts/speckit.archive.md

.cursor/*
!.cursor/commands/
.cursor/commands/*
!.cursor/commands/speckit.archive.md

# Archive scripts (whitelist approach - track only core, config, and hooks)
.specify/scripts/bash/archive/*
!.specify/scripts/bash/archive/core/
!.specify/scripts/bash/archive/config/
!.specify/scripts/bash/archive/hooks/
EOF
            log "✅ .gitignore updated (Spec-Kit Archive Extension)"
        else
            log "✅ .gitignore already configured for Spec-Kit Archive Extension"
        fi
    fi
}

show_next_steps() {
    local target="$1"
    
    cat <<EOF

╔═══════════════════════════════════════════════════════════════════════╗
║  Installation Complete! 🎉                                            ║
╚═══════════════════════════════════════════════════════════════════════╝

📦 Installed to: $target/.specify/scripts/bash/archive/

🚀 Quick Start:

1. Ensure constitution.md exists:
   $target/.specify/memory/constitution.md

2. Complete a feature spec:
   $target/specs/00N-my-feature/
   ├── spec.md
   ├── plan.md
   ├── data-model.md
   └── contracts/

3. Archive the feature:
   cd $target
   .specify/scripts/bash/archive/core/archive-feature.sh --feature 00N-my-feature

4. Or use AI command:
   /speckit.archive

💡 Spec-Kit Integration:

When creating new features with /specify, avoid number conflicts with archived features:

   # Get next safe feature number
   source .specify/scripts/bash/archive/hooks/pre-specify.sh
   echo \$SPECKIT_NEXT_FEATURE_NUMBER

   # Validate before creating
   .specify/scripts/bash/archive/core/check-feature-conflict.sh 005

📚 Documentation:
   - README: $target/.specify/scripts/bash/archive/README.md
   - GitHub: https://github.com/shohu/spec-kit-archive-extension

💡 Tips:
   - The system uses constitution-driven merge strategies
   - User stories and requirements are intelligently accumulated
   - Tasks.md is excluded (completed tasks don't need archiving)

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            if [[ $# -lt 2 ]]; then
                error "--target requires a directory path"
            fi
            TARGET_DIR="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Default to current directory
if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$(pwd)"
fi

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

log "spec-kit-archive-extension v$VERSION"
log "Target: $TARGET_DIR"
echo ""

# Run installation
check_requirements "$TARGET_DIR"
install_archive_system "$TARGET_DIR"
install_prompt "$TARGET_DIR"
check_constitution "$TARGET_DIR"
update_gitignore "$TARGET_DIR"
show_next_steps "$TARGET_DIR"

exit 0

