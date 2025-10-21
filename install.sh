#!/usr/bin/env bash

set -euo pipefail

# spec-kit-archive-extension Installer
# 
# Constitution-driven intelligent spec archive system for Spec-Kit projects
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/spec-kit-archive-extension/main/install.sh | bash
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
  curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/spec-kit-archive-extension/main/install.sh | bash

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
        cp -r "$SCRIPT_DIR" "$archive_dest"
        # Remove install.sh from destination (meta-script)
        rm -f "$archive_dest/install.sh"
    else
        error "Archive source directory not found: $SCRIPT_DIR"
    fi
    
    log "✅ Archive system installed"
}

install_prompt() {
    local target="$1"
    
    log "Installing AI prompts..."
    
    # Install for Codex
    local codex_dest="$target/.codex/prompts"
    mkdir -p "$codex_dest"
    
    if [[ -f "$SCRIPT_DIR/.codex/prompts/speckit.archive.md" ]]; then
        cp "$SCRIPT_DIR/.codex/prompts/speckit.archive.md" "$codex_dest/"
        log "✅ Codex prompt installed (.codex/prompts/)"
    else
        log "⚠️  Codex prompt not found"
    fi
    
    # Install for Cursor
    local cursor_dest="$target/.cursor/prompts"
    mkdir -p "$cursor_dest"
    
    if [[ -f "$SCRIPT_DIR/.cursor/prompts/speckit.archive.md" ]]; then
        cp "$SCRIPT_DIR/.cursor/prompts/speckit.archive.md" "$cursor_dest/"
        log "✅ Cursor prompt installed (.cursor/prompts/)"
    else
        log "⚠️  Cursor prompt not found"
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
        log "   See: https://github.com/YOUR_USERNAME/spec-kit-archive-extension#constitution-setup"
    else
        log "✅ constitution.md found"
    fi
}

update_gitignore() {
    local target="$1"
    local gitignore="$target/.gitignore"
    
    if [[ -f "$gitignore" ]]; then
        # Check if .codex rules exist
        if ! grep -q "^\.codex/\*" "$gitignore" 2>/dev/null; then
            log "Adding AI editor ignore rules to .gitignore"
            cat >> "$gitignore" <<'EOF'

# Spec-Kit tooling artifacts (AI editor prompts)
.codex/*
!.codex/prompts/
.codex/prompts/*
!.codex/prompts/speckit.archive.md

.cursor/*
!.cursor/prompts/
.cursor/prompts/*
!.cursor/prompts/speckit.archive.md
EOF
            log "✅ .gitignore updated (Codex + Cursor)"
        else
            log "✅ .gitignore already configured"
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

📚 Documentation:
   - README: $target/.specify/scripts/bash/archive/README.md
   - GitHub: https://github.com/YOUR_USERNAME/spec-kit-archive-extension

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

