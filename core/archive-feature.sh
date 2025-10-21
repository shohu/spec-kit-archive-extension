#!/usr/bin/env bash

set -euo pipefail

JSON_MODE=false
FEATURE_SLUG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --feature)
            if [[ $# -lt 2 ]]; then
                echo "Error: --feature requires a value" >&2
                exit 1
            fi
            FEATURE_SLUG="$2"
            shift 2
            ;;
        --help|-h)
            cat <<'EOF'
Usage: archive-feature.sh [--json] --feature <feature-directory>

Moves a completed feature spec from specs/<feature> into specs/archive/<feature>
and synchronises relevant documents into specs/latest/.

Options:
  --feature <dir>   Required. Name of the feature directory (e.g. 002-specify-scripts-bash)
  --json            Emit machine-readable JSON summary
  --help, -h        Show this help
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$FEATURE_SLUG" ]]; then
    echo "Error: --feature is required" >&2
    exit 1
fi

if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    echo "Error: Must be executed inside a git repository" >&2
    exit 1
fi

cd "$REPO_ROOT"

FEATURE_DIR="$REPO_ROOT/specs/$FEATURE_SLUG"
if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Error: Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

ARCHIVE_ROOT="$REPO_ROOT/specs/archive"
LATEST_DIR="$REPO_ROOT/specs/latest"

mkdir -p "$ARCHIVE_ROOT"
mkdir -p "$LATEST_DIR"

ARCHIVE_DIR="$ARCHIVE_ROOT/$FEATURE_SLUG"
if [[ -e "$ARCHIVE_DIR" ]]; then
    echo "Error: Archive destination already exists: $ARCHIVE_DIR" >&2
    exit 1
fi

# Collect information about unfinished tasks (if any)
UNFINISHED_TASKS=()
TASKS_FILE="$FEATURE_DIR/tasks.md"
if [[ -f "$TASKS_FILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[[[:space:]]\] ]]; then
            UNFINISHED_TASKS+=("$line")
        fi
    done < "$TASKS_FILE"
fi

SYNCED_ITEMS=()

# Validate implementation matches specification (informational)
VALIDATE_SCRIPT="$REPO_ROOT/.specify/scripts/bash/archive/core/validate-implementation.sh"
if [[ -f "$VALIDATE_SCRIPT" ]]; then
    echo "Validating implementation alignment..."
    if bash "$VALIDATE_SCRIPT" --feature "$FEATURE_SLUG" 2>&1; then
        echo "✅ Implementation validation passed"
    else
        echo "⚠️  Implementation validation warnings detected (continuing...)"
    fi
    echo ""
fi

# Files to synchronise into specs/latest/
# Note: tasks.md is excluded as tasks are completed at archive time
SYNC_FILES=(
    "spec.md"
    "plan.md"
    "data-model.md"
    "quickstart.md"
    "research.md"
)

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$FEATURE_DIR/$file" ]]; then
        mkdir -p "$(dirname "$LATEST_DIR/$file")"
        
        # Check if file exists in latest/ and needs merging
        if [[ -f "$LATEST_DIR/$file" && "$file" =~ \.(md|markdown)$ ]]; then
            # Use intelligent merge for Markdown files
            MERGE_SCRIPT="$REPO_ROOT/.specify/scripts/bash/archive/core/merge-spec.sh"
            if [[ -f "$MERGE_SCRIPT" ]]; then
                echo "Merging $file with existing latest/$file..."
                bash "$MERGE_SCRIPT" \
                    --base "$LATEST_DIR/$file" \
                    --incoming "$FEATURE_DIR/$file" \
                    --output "$LATEST_DIR/$file" 2>&1 || {
                    echo "Warning: Merge failed for $file, using simple copy" >&2
                    cp "$FEATURE_DIR/$file" "$LATEST_DIR/$file"
                }
            else
                echo "Warning: merge-spec.sh not found, using simple copy" >&2
                cp "$FEATURE_DIR/$file" "$LATEST_DIR/$file"
            fi
        else
            # First time or non-Markdown file, simple copy
            cp "$FEATURE_DIR/$file" "$LATEST_DIR/$file"
        fi
        
        SYNCED_ITEMS+=("latest/$file")
    fi
done

# Optional directories (e.g., contracts)
if [[ -d "$FEATURE_DIR/contracts" ]]; then
    rsync -a --delete "$FEATURE_DIR/contracts/" "$LATEST_DIR/contracts/"
    SYNCED_ITEMS+=("latest/contracts/")
fi

# Move the feature directory into archive
mv "$FEATURE_DIR" "$ARCHIVE_DIR"

sorted_sync=$(printf '%s\n' "${SYNCED_ITEMS[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')

if $JSON_MODE; then
    printf '{'
    printf '"archived_path":"%s"' "$ARCHIVE_DIR"
    printf ',"latest_path":"%s"' "$LATEST_DIR"
    printf ',"synced_items":"%s"' "$sorted_sync"
    if [[ ${#UNFINISHED_TASKS[@]} -gt 0 ]]; then
        printf ',"warnings":['
        for ((i=0; i<${#UNFINISHED_TASKS[@]}; i++)); do
            printf '"%s"' "$(echo "${UNFINISHED_TASKS[$i]}" | sed 's/"/\\"/g')"
            if [[ $i -lt $((${#UNFINISHED_TASKS[@]}-1)) ]]; then
                printf ','
            fi
        done
        printf ']'
    fi
    printf '}\n'
else
    echo "Archived to: $ARCHIVE_DIR"
    if [[ -n "$sorted_sync" ]]; then
        echo "Synced into specs/latest/: ${sorted_sync//,/ }"
    else
        echo "No files synced into specs/latest/"
    fi
    if [[ ${#UNFINISHED_TASKS[@]} -gt 0 ]]; then
        echo "Warnings: Unfinished tasks detected in $TASKS_FILE"
        printf '  %s\n' "${UNFINISHED_TASKS[@]}"
    fi
fi
