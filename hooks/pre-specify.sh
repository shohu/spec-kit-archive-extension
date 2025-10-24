#!/usr/bin/env bash

# pre-specify.sh
# Hook for spec-kit /specify command to avoid feature number conflicts with archived features
#
# Usage:
#   source .specify/scripts/bash/archive/hooks/pre-specify.sh
#   echo $SPECKIT_NEXT_FEATURE_NUMBER
#
# This script provides the next available feature number by checking both:
# - specs/[0-9][0-9][0-9]-*/ (current features)
# - specs/archive/[0-9][0-9][0-9]-*/ (archived features)

get_next_feature_number() {
    local repo_root

    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        repo_root=$(git rev-parse --show-toplevel)
    else
        echo "0" >&2
        return 1
    fi

    # Get max number from current specs/
    local max_current=0
    if [[ -d "$repo_root/specs" ]]; then
        local current_features
        # Use nullglob-like behavior with find instead of ls to avoid error messages
        current_features=$(find "$repo_root/specs" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null || true)
        if [[ -n "$current_features" ]]; then
            max_current=$(echo "$current_features" | \
                         sed 's/.*\/\([0-9][0-9][0-9]\)-.*/\1/' | \
                         sed 's/^0*//' | \
                         sort -nr | \
                         head -n1 || echo "0")
            # Handle empty string case
            [[ -z "$max_current" ]] && max_current=0
        fi
    fi

    # Get max number from archived specs/archive/
    local max_archived=0
    if [[ -d "$repo_root/specs/archive" ]]; then
        local archived_features
        # Use find instead of ls to avoid error messages
        archived_features=$(find "$repo_root/specs/archive" -maxdepth 1 -type d -name '[0-9][0-9][0-9]-*' 2>/dev/null || true)
        if [[ -n "$archived_features" ]]; then
            max_archived=$(echo "$archived_features" | \
                          sed 's/.*\/\([0-9][0-9][0-9]\)-.*/\1/' | \
                          sed 's/^0*//' | \
                          sort -nr | \
                          head -n1 || echo "0")
            # Handle empty string case
            [[ -z "$max_archived" ]] && max_archived=0
        fi
    fi

    # Return the larger number + 1
    local max_number=$max_current
    if [[ $max_archived -gt $max_current ]]; then
        max_number=$max_archived
    fi

    echo $((max_number + 1))
}

# Export as environment variable for easy access
SPECKIT_NEXT_FEATURE_NUMBER=$(get_next_feature_number)
export SPECKIT_NEXT_FEATURE_NUMBER

# Optional: Print debug info if SPECKIT_DEBUG is set
if [[ -n "${SPECKIT_DEBUG:-}" ]]; then
    echo "🔍 [pre-specify hook] Next feature number: $SPECKIT_NEXT_FEATURE_NUMBER" >&2
fi
