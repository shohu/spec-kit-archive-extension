#!/usr/bin/env bash

set -euo pipefail

# check-feature-conflict.sh
# Validates that a feature number doesn't conflict with archived features
#
# Usage:
#   check-feature-conflict.sh <feature-number>
#   check-feature-conflict.sh 003
#
# Exit codes:
#   0 - No conflict, number is available
#   1 - Conflict detected or error

FEATURE_NUMBER=""
VERBOSE=false

usage() {
    cat <<'EOF'
Usage: check-feature-conflict.sh <feature-number> [--verbose]

Validates that a feature number doesn't conflict with archived features.

Arguments:
  feature-number    Three-digit feature number (e.g., 001, 002)

Options:
  --verbose, -v     Show detailed information
  --help, -h        Show this help

Examples:
  check-feature-conflict.sh 003
  check-feature-conflict.sh 005 --verbose

Exit codes:
  0 - No conflict detected
  1 - Conflict detected or error
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            ;;
        [0-9][0-9][0-9])
            FEATURE_NUMBER="$1"
            shift
            ;;
        *)
            echo "Error: Unknown option or invalid feature number: $1" >&2
            echo "Feature number must be three digits (e.g., 001, 002)" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$FEATURE_NUMBER" ]]; then
    echo "Error: Feature number is required" >&2
    echo "Usage: check-feature-conflict.sh <feature-number>" >&2
    exit 1
fi

# Validate feature number format
if [[ ! "$FEATURE_NUMBER" =~ ^[0-9][0-9][0-9]$ ]]; then
    echo "Error: Feature number must be exactly three digits (e.g., 001, 002)" >&2
    exit 1
fi

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    echo "Error: Must be executed inside a git repository" >&2
    exit 1
fi

# Check for conflicts in specs/
CONFLICT_CURRENT=""
if [[ -d "$REPO_ROOT/specs" ]]; then
    CONFLICT_CURRENT=$(ls -1d "$REPO_ROOT/specs/$FEATURE_NUMBER-"* 2>/dev/null || true)
fi

# Check for conflicts in specs/archive/
CONFLICT_ARCHIVED=""
if [[ -d "$REPO_ROOT/specs/archive" ]]; then
    CONFLICT_ARCHIVED=$(ls -1d "$REPO_ROOT/specs/archive/$FEATURE_NUMBER-"* 2>/dev/null || true)
fi

# Report results
if [[ -n "$CONFLICT_CURRENT" ]]; then
    echo "❌ Error: Feature number $FEATURE_NUMBER already exists in specs/" >&2
    echo "" >&2
    echo "📦 Current feature(s) with this number:" >&2
    echo "$CONFLICT_CURRENT" | sed 's/^/   /' >&2
    echo "" >&2
    echo "💡 Suggestion: Use a different feature number or archive the existing feature first" >&2
    exit 1
fi

if [[ -n "$CONFLICT_ARCHIVED" ]]; then
    echo "❌ Error: Feature number $FEATURE_NUMBER already exists in archive/" >&2
    echo "" >&2
    echo "📦 Archived feature(s) with this number:" >&2
    echo "$CONFLICT_ARCHIVED" | sed 's/^/   /' >&2
    echo "" >&2
    echo "💡 Suggestion: Use the next available number to avoid confusion" >&2
    echo "" >&2

    # Suggest next available number
    if [[ -f "$REPO_ROOT/.specify/scripts/bash/archive/hooks/pre-specify.sh" ]]; then
        source "$REPO_ROOT/.specify/scripts/bash/archive/hooks/pre-specify.sh"
        printf "   Next available: %03d\n" "$SPECKIT_NEXT_FEATURE_NUMBER" >&2
    fi

    exit 1
fi

# Success
if $VERBOSE; then
    echo "✅ Feature number $FEATURE_NUMBER is available"
    echo ""
    echo "📊 Summary:"
    echo "   - No conflicts in specs/"
    echo "   - No conflicts in specs/archive/"
    echo "   - Safe to create specs/$FEATURE_NUMBER-<feature-name>/"
else
    echo "✅ Feature number $FEATURE_NUMBER is available"
fi

exit 0
