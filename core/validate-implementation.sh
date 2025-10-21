#!/usr/bin/env bash

set -euo pipefail

# validate-implementation.sh
# Validates that spec.md, plan.md, and data-model.md match actual implementation

FEATURE_DIR=""
JSON_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --feature)
            if [[ $# -lt 2 ]]; then
                echo "Error: --feature requires a value" >&2
                exit 1
            fi
            FEATURE_DIR="$2"
            shift 2
            ;;
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            cat <<'EOF'
Usage: validate-implementation.sh --feature <feature-directory> [--json]

Validates that specification documents match actual implementation.

Checks:
  - spec.md: User stories have corresponding tests
  - plan.md: Mentioned files/directories exist
  - data-model.md: Entities exist in src/ or persistence/

Options:
  --feature <dir>   Required. Feature directory to validate
  --json            Output results as JSON
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

if [[ -z "$FEATURE_DIR" ]]; then
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

SPEC_FILE="$REPO_ROOT/specs/$FEATURE_DIR/spec.md"
PLAN_FILE="$REPO_ROOT/specs/$FEATURE_DIR/plan.md"
DATA_MODEL_FILE="$REPO_ROOT/specs/$FEATURE_DIR/data-model.md"

declare -a WARNINGS=()
declare -a ERRORS=()

# Check 1: spec.md - User stories should have tests
check_user_stories() {
    if [[ ! -f "$SPEC_FILE" ]]; then
        ERRORS+=("spec.md not found")
        return
    fi
    
    # Extract user story priorities (P1, P2, P3)
    # Support multiple priority formats: "Priority: P1", "優先度: P1", "**Priority**: P1"
    local p1_stories=$(grep -ciE "(Priority|優先度):[[:space:]]*P1" "$SPEC_FILE" || echo "0")
    
    # Check if tests exist
    if [[ ! -d "$REPO_ROOT/tests" ]]; then
        WARNINGS+=("No tests/ directory found, but spec defines $p1_stories P1 user stories")
        return
    fi
    
    # Count test files (unit, integration, e2e)
    local test_count=$(find "$REPO_ROOT/tests" -name "*.test.ts" -o -name "*.spec.ts" | wc -l | xargs)
    
    if [[ "$p1_stories" -gt 0 && "$test_count" -eq 0 ]]; then
        ERRORS+=("spec.md defines $p1_stories P1 stories but no test files found")
    elif [[ "$test_count" -lt "$p1_stories" ]]; then
        WARNINGS+=("spec.md defines $p1_stories P1 stories but only $test_count test files found")
    fi
}

# Check 2: plan.md - Mentioned files should exist
check_plan_files() {
    if [[ ! -f "$PLAN_FILE" ]]; then
        ERRORS+=("plan.md not found")
        return
    fi
    
    # Extract code block paths (src/, tests/, etc.)
    local mentioned_files=$(grep -o 'src/[^[:space:]`"]*' "$PLAN_FILE" | sort -u)
    
    if [[ -z "$mentioned_files" ]]; then
        WARNINGS+=("plan.md does not mention any src/ files")
        return
    fi
    
    local missing_count=0
    while IFS= read -r file_path; do
        if [[ -n "$file_path" && ! -e "$REPO_ROOT/$file_path" ]]; then
            missing_count=$((missing_count + 1))
        fi
    done <<< "$mentioned_files"
    
    if [[ "$missing_count" -gt 0 ]]; then
        WARNINGS+=("plan.md mentions $missing_count files that don't exist in src/")
    fi
}

# Check 3: data-model.md - Entities should exist in code
check_data_model() {
    if [[ ! -f "$DATA_MODEL_FILE" ]]; then
        WARNINGS+=("data-model.md not found (optional)")
        return
    fi
    
    # Extract entity names (## EntityName pattern)
    local entities=$(grep "^## [A-Z][a-zA-Z]*$" "$DATA_MODEL_FILE" | sed 's/^## //' || echo "")
    
    if [[ -z "$entities" ]]; then
        WARNINGS+=("data-model.md has no entity definitions")
        return
    fi
    
    local missing_entities=()
    while IFS= read -r entity; do
        if [[ -z "$entity" ]]; then continue; fi
        
        # Check if entity exists in src/ or persistence/
        local entity_lower=$(echo "$entity" | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//')
        local entity_kebab=$(echo "$entity" | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//')
        
        # Try various naming conventions
        if ! grep -rq "$entity" "$REPO_ROOT/src" "$REPO_ROOT/persistence" 2>/dev/null &&
           ! grep -rq "$entity_lower" "$REPO_ROOT/src" "$REPO_ROOT/persistence" 2>/dev/null &&
           ! grep -rq "$entity_kebab" "$REPO_ROOT/src" "$REPO_ROOT/persistence" 2>/dev/null; then
            missing_entities+=("$entity")
        fi
    done <<< "$entities"
    
    if [[ ${#missing_entities[@]} -gt 0 ]]; then
        WARNINGS+=("data-model.md defines entities not found in code: ${missing_entities[*]}")
    fi
}

# Run all checks
check_user_stories
check_plan_files
check_data_model

# Output results
if $JSON_MODE; then
    printf '{'
    printf '"feature":"%s"' "$FEATURE_DIR"
    printf ',"errors":%d' "${#ERRORS[@]}"
    printf ',"warnings":%d' "${#WARNINGS[@]}"
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        printf ',"error_messages":['
        for ((i=0; i<${#ERRORS[@]}; i++)); do
            printf '"%s"' "${ERRORS[$i]//\"/\\\"}"
            if [[ $i -lt $((${#ERRORS[@]}-1)) ]]; then
                printf ','
            fi
        done
        printf ']'
    fi
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        printf ',"warning_messages":['
        for ((i=0; i<${#WARNINGS[@]}; i++)); do
            printf '"%s"' "${WARNINGS[$i]//\"/\\\"}"
            if [[ $i -lt $((${#WARNINGS[@]}-1)) ]]; then
                printf ','
            fi
        done
        printf ']'
    fi
    
    printf '}\n'
else
    echo "Validation Results for: $FEATURE_DIR"
    echo "========================================"
    
    if [[ ${#ERRORS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
        echo "✅ All checks passed"
        exit 0
    fi
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo ""
        echo "❌ Errors:"
        for error in "${ERRORS[@]}"; do
            echo "  - $error"
        done
    fi
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo ""
        echo "⚠️  Warnings:"
        for warning in "${WARNINGS[@]}"; do
            echo "  - $warning"
        done
    fi
fi

# Exit with error if there are errors (warnings are OK)
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    exit 1
fi

exit 0

