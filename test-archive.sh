#!/usr/bin/env bash
#
# Test script for spec-kit-archive-extension
# Tests archiving functionality on this repository's own specs
#

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Test 1: Verify directory structure
test_structure() {
    log "Testing directory structure..."
    
    if [[ ! -d ".specify/scripts/bash/archive/core" ]]; then
        error "Archive scripts directory not found"
        return 1
    fi
    
    if [[ ! -f ".specify/memory/constitution.md" ]]; then
        error "Constitution file not found"
        return 1
    fi
    
    if [[ ! -d "specs/001-initial-setup" ]]; then
        error "Test spec 001-initial-setup not found"
        return 1
    fi
    
    if [[ ! -d "specs/002-git-integration" ]]; then
        error "Test spec 002-git-integration not found"
        return 1
    fi
    
    success "Directory structure verified"
    return 0
}

# Test 2: Verify scripts are executable and linked
test_scripts() {
    log "Testing script setup..."
    
    local script=".specify/scripts/bash/archive/core/archive-feature.sh"
    if [[ ! -x "$script" ]]; then
        error "archive-feature.sh not executable"
        return 1
    fi
    
    if [[ ! -L "$script" ]]; then
        warn "archive-feature.sh is not a symlink (expected for test setup)"
    fi
    
    # Test help output
    if ! bash "$script" --help >/dev/null 2>&1; then
        error "archive-feature.sh --help failed"
        return 1
    fi
    
    success "Scripts verified"
    return 0
}

# Test 3: Dry run archive (no actual archiving)
test_dry_run() {
    log "Testing spec file structure..."
    
    # Check if spec files are valid Markdown
    for spec in specs/001-initial-setup/spec.md specs/002-git-integration/spec.md; do
        if [[ ! -f "$spec" ]]; then
            error "Spec file not found: $spec"
            return 1
        fi
        
        # Check for required sections
        if ! grep -q "## User Stories" "$spec"; then
            error "Missing 'User Stories' section in $spec"
            return 1
        fi
        
        if ! grep -q "## Functional Requirements" "$spec"; then
            error "Missing 'Functional Requirements' section in $spec"
            return 1
        fi
    done
    
    success "Spec files structure verified"
    return 0
}

# Test 4: Test parse-markdown-sections.awk
test_parser() {
    log "Testing Markdown parser..."
    
    local awk_script="core/parse-markdown-sections.awk"
    if [[ ! -f "$awk_script" ]]; then
        error "parse-markdown-sections.awk not found"
        return 1
    fi
    
    # Test parsing a spec file
    local test_file="specs/001-initial-setup/spec.md"
    if ! awk -f "$awk_script" "$test_file" > /dev/null; then
        error "Parser failed on $test_file"
        return 1
    fi
    
    success "Markdown parser works"
    return 0
}

# Test 5: Actual archive test (with backup)
test_archive() {
    log "Testing actual archive operation..."
    
    # Create backup
    if [[ -d "specs/latest" ]]; then
        warn "specs/latest already exists, backing up..."
        mv specs/latest specs/latest.backup
    fi
    
    if [[ -d "specs/archive" ]]; then
        warn "specs/archive already exists, backing up..."
        mv specs/archive specs/archive.backup
    fi
    
    # Run archive for 001-initial-setup
    log "Archiving 001-initial-setup..."
    if bash .specify/scripts/bash/archive/core/archive-feature.sh \
        --feature 001-initial-setup --json > /tmp/archive-output.json 2>&1; then
        
        success "Archive command succeeded"
        
        # Verify outputs
        if [[ ! -d "specs/archive/001-initial-setup" ]]; then
            error "Feature not moved to archive"
            return 1
        fi
        
        if [[ ! -d "specs/latest" ]]; then
            error "specs/latest not created"
            return 1
        fi
        
        if [[ ! -f "specs/latest/spec.md" ]]; then
            error "specs/latest/spec.md not created"
            return 1
        fi
        
        # Check JSON output
        if ! cat /tmp/archive-output.json | grep -q "archived_path"; then
            error "Invalid JSON output"
            return 1
        fi
        
        success "Archive operation completed successfully"
        
        # Show results
        log "Archive contents:"
        ls -la specs/archive/001-initial-setup/
        
        log "Latest contents:"
        ls -la specs/latest/
        
        log "Latest spec.md preview:"
        head -n 20 specs/latest/spec.md
        
    else
        error "Archive command failed"
        cat /tmp/archive-output.json
        return 1
    fi
    
    return 0
}

# Test 6: Test second archive (merge test)
test_second_archive() {
    log "Testing second archive (merge test)..."
    
    # Archive 002-git-integration
    log "Archiving 002-git-integration..."
    if bash .specify/scripts/bash/archive/core/archive-feature.sh \
        --feature 002-git-integration --json > /tmp/archive-output-2.json 2>&1; then
        
        success "Second archive succeeded"
        
        # Verify merge
        if [[ ! -d "specs/archive/002-git-integration" ]]; then
            error "Second feature not moved to archive"
            return 1
        fi
        
        # Check if user stories were accumulated
        local story_count=$(grep -c "### US-" specs/latest/spec.md || true)
        if [[ $story_count -lt 2 ]]; then
            error "User stories not accumulated properly (found $story_count, expected >= 2)"
            return 1
        fi
        
        success "User stories accumulated: $story_count stories found"
        
        # Check if requirements were merged
        local req_count=$(grep -c "### FR-" specs/latest/spec.md || true)
        if [[ $req_count -lt 2 ]]; then
            error "Requirements not merged properly (found $req_count, expected >= 2)"
            return 1
        fi
        
        success "Requirements merged: $req_count requirements found"
        
        log "Merged spec.md preview:"
        head -n 50 specs/latest/spec.md
        
    else
        error "Second archive failed"
        cat /tmp/archive-output-2.json
        return 1
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    log "Cleanup..."
    
    read -p "Remove test archives and restore backups? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Restore backups if they exist
        if [[ -d "specs/latest.backup" ]]; then
            rm -rf specs/latest
            mv specs/latest.backup specs/latest
            log "Restored specs/latest backup"
        fi
        
        if [[ -d "specs/archive.backup" ]]; then
            rm -rf specs/archive
            mv specs/archive.backup specs/archive
            log "Restored specs/archive backup"
        fi
        
        # Restore original feature directories
        if [[ -d "specs/archive/001-initial-setup" ]]; then
            mv specs/archive/001-initial-setup specs/
            log "Restored 001-initial-setup"
        fi
        
        if [[ -d "specs/archive/002-git-integration" ]]; then
            mv specs/archive/002-git-integration specs/
            log "Restored 002-git-integration"
        fi
        
        # Remove empty archive directory
        if [[ -d "specs/archive" ]] && [[ -z "$(ls -A specs/archive)" ]]; then
            rmdir specs/archive
        fi
        
        success "Cleanup completed"
    else
        log "Keeping test results for inspection"
        log "  - specs/latest/ contains merged specs"
        log "  - specs/archive/ contains archived features"
    fi
}

# Main test runner
main() {
    echo ""
    echo "=========================================="
    echo "  Spec-Kit Archive Extension Test Suite"
    echo "=========================================="
    echo ""
    
    local failed=0
    
    test_structure || ((failed++))
    echo ""
    
    test_scripts || ((failed++))
    echo ""
    
    test_dry_run || ((failed++))
    echo ""
    
    test_parser || ((failed++))
    echo ""
    
    test_archive || ((failed++))
    echo ""
    
    test_second_archive || ((failed++))
    echo ""
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        success "All tests passed! 🎉"
    else
        error "$failed test(s) failed"
    fi
    echo "=========================================="
    echo ""
    
    cleanup
    
    return $failed
}

# Run tests
main "$@"

