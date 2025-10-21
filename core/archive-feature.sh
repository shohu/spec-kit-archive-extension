#!/usr/bin/env bash

set -euo pipefail

JSON_MODE=false
FEATURE_SLUG=""
WITH_MERGE=false

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
        --with-merge)
            WITH_MERGE=true
            shift
            ;;
        --help|-h)
            cat <<'EOF'
Usage: archive-feature.sh [--json] --feature <feature-directory> [--with-merge]

Moves a completed feature spec from specs/<feature> into specs/archive/<feature>
and synchronises relevant documents into specs/latest/.

Options:
  --feature <dir>   Required. Name of the feature directory (e.g. 002-specify-scripts-bash)
  --json            Emit machine-readable JSON summary
  --with-merge      Prompt to merge current branch into parent branch after archiving
  --help, -h        Show this help

Git Integration:
  When --with-merge is specified and you're on a spec branch (e.g. feat/specs-002-*),
  the script will detect the parent branch and prompt for merge after archiving.
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

# Git branch merge integration
MERGE_PERFORMED=false
MERGE_ERROR=""

if $WITH_MERGE && ! $JSON_MODE; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    # Check if current branch looks like a spec feature branch
    if [[ "$CURRENT_BRANCH" =~ ^feat/specs-[0-9]{3}- ]]; then
        echo ""
        echo "📌 Git Integration: Detected spec branch '$CURRENT_BRANCH'"
        
        # Try to detect parent branch
        PARENT_BRANCH=$(git show-branch -a 2>/dev/null | \
            grep '\*' | grep -v "$CURRENT_BRANCH" | \
            head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/\^.*//' || echo "")
        
        # Fallback: check common parent branches
        if [[ -z "$PARENT_BRANCH" ]]; then
            for candidate in main master develop; do
                if git show-ref --verify --quiet "refs/heads/$candidate"; then
                    PARENT_BRANCH="$candidate"
                    break
                fi
            done
        fi
        
        if [[ -n "$PARENT_BRANCH" ]]; then
            echo "📍 Detected parent branch: $PARENT_BRANCH"
            echo ""
            read -p "🔀 Merge archived changes into '$PARENT_BRANCH'? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "🔄 Merging $CURRENT_BRANCH into $PARENT_BRANCH..."
                
                # Check for uncommitted changes
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo "⚠️  Uncommitted changes detected. Please commit or stash them first."
                    MERGE_ERROR="Uncommitted changes present"
                else
                    # Perform the merge
                    if git checkout "$PARENT_BRANCH" 2>&1 && \
                       git merge --no-ff "$CURRENT_BRANCH" -m "feat(specs): merge archived $FEATURE_SLUG" 2>&1; then
                        echo "✅ Successfully merged into $PARENT_BRANCH"
                        MERGE_PERFORMED=true
                        
                        # Optional: delete the feature branch
                        read -p "🗑️  Delete branch '$CURRENT_BRANCH'? (y/N): " -n 1 -r
                        echo ""
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            git branch -d "$CURRENT_BRANCH" 2>&1 && \
                                echo "✅ Branch deleted: $CURRENT_BRANCH" || \
                                echo "⚠️  Could not delete branch (use -D to force)"
                        fi
                    else
                        MERGE_ERROR="Merge conflict or checkout failed"
                        echo "❌ Merge failed. Please resolve manually."
                        # Try to return to original branch
                        git checkout "$CURRENT_BRANCH" 2>/dev/null || true
                    fi
                fi
            else
                echo "⏭️  Merge skipped"
            fi
        else
            echo "⚠️  Could not detect parent branch automatically"
            echo "💡 Tip: Manually merge with: git checkout <parent> && git merge --no-ff $CURRENT_BRANCH"
        fi
    else
        echo "ℹ️  Not on a spec feature branch, skipping merge prompt"
    fi
fi

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
    if $WITH_MERGE; then
        printf ',"merge_performed":%s' "$($MERGE_PERFORMED && echo true || echo false)"
        if [[ -n "$MERGE_ERROR" ]]; then
            printf ',"merge_error":"%s"' "$MERGE_ERROR"
        fi
    fi
    printf '}\n'
else
    echo ""
    echo "✅ Archive complete!"
    echo "📦 Archived to: $ARCHIVE_DIR"
    if [[ -n "$sorted_sync" ]]; then
        echo "📝 Synced into specs/latest/: ${sorted_sync//,/ }"
    else
        echo "📝 No files synced into specs/latest/"
    fi
    if [[ ${#UNFINISHED_TASKS[@]} -gt 0 ]]; then
        echo "⚠️  Warnings: Unfinished tasks detected in $TASKS_FILE"
        printf '  %s\n' "${UNFINISHED_TASKS[@]}"
    fi
fi
