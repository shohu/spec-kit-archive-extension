#!/usr/bin/env bash

set -euo pipefail

# merge-spec.sh
# Intelligently merges Markdown specification files based on constitution principles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONSTITUTION_FILE=""
BASE_FILE=""
INCOMING_FILE=""
OUTPUT_FILE=""

usage() {
    cat <<'EOF'
Usage: merge-spec.sh [OPTIONS]

Intelligently merges specification Markdown files based on constitution principles.

Options:
  --constitution FILE  Path to constitution.md (for principle validation)
  --base FILE          Path to base/existing spec file (e.g., specs/latest/spec.md)
  --incoming FILE      Path to incoming spec file (e.g., specs/002-.../spec.md)
  --output FILE        Path to output merged file
  --help, -h           Show this help

Example:
  merge-spec.sh \
    --constitution .specify/memory/constitution.md \
    --base specs/latest/spec.md \
    --incoming specs/002-feature/spec.md \
    --output specs/latest/spec.md
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --constitution)
            CONSTITUTION_FILE="$2"
            shift 2
            ;;
        --base)
            BASE_FILE="$2"
            shift 2
            ;;
        --incoming)
            INCOMING_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$BASE_FILE" || -z "$INCOMING_FILE" || -z "$OUTPUT_FILE" ]]; then
    echo "Error: --base, --incoming, and --output are required" >&2
    exit 1
fi

if [[ ! -f "$BASE_FILE" ]]; then
    echo "Error: Base file not found: $BASE_FILE" >&2
    exit 1
fi

if [[ ! -f "$INCOMING_FILE" ]]; then
    echo "Error: Incoming file not found: $INCOMING_FILE" >&2
    exit 1
fi

MERGE_RULES="$SCRIPT_DIR/../config/merge-rules.json"
if [[ ! -f "$MERGE_RULES" ]]; then
    echo "Error: Merge rules not found: $MERGE_RULES" >&2
    exit 1
fi

# Create temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Parse both files into sections
parse_markdown() {
    local input_file="$1"
    local output_prefix="$2"
    
    awk -f "$SCRIPT_DIR/parse-markdown-sections.awk" "$input_file" | \
    awk -v prefix="$output_prefix" '
        /^SECTION_START\|/ {
            if (section_file != "") {
                close(section_file)
            }
            section_count++
            section_file = prefix "_" sprintf("%03d", section_count) ".txt"
            
            # Extract level and heading
            sub(/^SECTION_START\|/, "")
            split($0, parts, "|")
            level = parts[1]
            heading = parts[2]
            
            print level > section_file
            print heading >> section_file
            next
        }
        
        /^SECTION_END$/ {
            if (section_file != "") {
                close(section_file)
                section_file = ""
            }
            next
        }
        
        {
            if (section_file != "") {
                print >> section_file
            }
        }
    '
}

echo "Parsing base file: $BASE_FILE"
parse_markdown "$BASE_FILE" "$TEMP_DIR/base"

echo "Parsing incoming file: $INCOMING_FILE"
parse_markdown "$INCOMING_FILE" "$TEMP_DIR/incoming"

# Read merge rules
get_merge_strategy() {
    local section_name="$1"
    
    # Check for pattern-based rules first
    # Phase pattern (tasks.md): Phase N: ... (reads from merge-rules.json if available)
    local phase_pattern=$(jq -r '.phase_pattern // "^##\\s*Phase\\s*\\d+:"' "$SCRIPT_DIR/../config/merge-rules.json" 2>/dev/null)
    if [[ -n "$phase_pattern" && "$section_name" =~ $phase_pattern ]]; then
        echo "accumulate"
        return
    fi
    
    # Fallback: support both English "Phase" and other language patterns
    if [[ "$section_name" =~ ^Phase[[:space:]]*[0-9]+: ]] || [[ "$section_name" =~ ^フェーズ[0-9]+: ]]; then
        echo "accumulate"
        return
    fi
    
    # Entity pattern (data-model.md): Capitalized words like ResourceCategory
    if [[ "$section_name" =~ ^[A-Z][a-zA-Z]+$ ]]; then
        echo "merge_entities"
        return
    fi
    
    # Extract strategy from JSON using grep and sed
    local strategy=$(grep -A 2 "\"$section_name\":" "$MERGE_RULES" | grep "strategy" | sed 's/.*"strategy": "\([^"]*\)".*/\1/')
    
    if [[ -z "$strategy" ]]; then
        # Try default strategy
        strategy=$(grep "default_strategy" "$MERGE_RULES" | sed 's/.*"default_strategy": "\([^"]*\)".*/\1/')
    fi
    
    echo "${strategy:-latest}"
}

# Merge sections
merge_sections() {
    local base_sections=("$TEMP_DIR"/base_*.txt)
    local incoming_sections=("$TEMP_DIR"/incoming_*.txt)
    
    declare -A processed_sections
    declare -A base_section_map
    declare -A incoming_section_map
    
    # Build section maps
    for section_file in "${base_sections[@]}"; do
        if [[ -f "$section_file" ]]; then
            local heading=$(sed -n '2p' "$section_file")
            base_section_map["$heading"]="$section_file"
        fi
    done
    
    for section_file in "${incoming_sections[@]}"; do
        if [[ -f "$section_file" ]]; then
            local heading=$(sed -n '2p' "$section_file")
            incoming_section_map["$heading"]="$section_file"
        fi
    done
    
    # Process all unique section headings
    local all_headings=()
    for heading in "${!base_section_map[@]}"; do
        all_headings+=("$heading")
    done
    for heading in "${!incoming_section_map[@]}"; do
        if [[ -z "${base_section_map[$heading]:-}" ]]; then
            all_headings+=("$heading")
        fi
    done
    
    # Sort headings to maintain order (base sections first, then new incoming sections)
    for section_file in "${base_sections[@]}"; do
        if [[ -f "$section_file" ]]; then
            local heading=$(sed -n '2p' "$section_file")
            
            if [[ -n "${processed_sections[$heading]:-}" ]]; then
                continue
            fi
            processed_sections["$heading"]=1
            
            merge_single_section "$heading"
        fi
    done
    
    # Add new sections from incoming that weren't in base
    for section_file in "${incoming_sections[@]}"; do
        if [[ -f "$section_file" ]]; then
            local heading=$(sed -n '2p' "$section_file")
            
            if [[ -n "${processed_sections[$heading]:-}" ]]; then
                continue
            fi
            processed_sections["$heading"]=1
            
            merge_single_section "$heading"
        fi
    done
}

merge_single_section() {
    local heading="$1"
    local base_file="${base_section_map[$heading]:-}"
    local incoming_file="${incoming_section_map[$heading]:-}"
    
    # Skip PREAMBLE sections (already handled separately)
    if [[ "$heading" == "PREAMBLE" ]]; then
        return
    fi
    
    if [[ -z "$incoming_file" ]]; then
        # Only in base, keep as-is
        if [[ -n "$base_file" ]]; then
            output_section "$base_file"
        fi
        return
    fi
    
    if [[ -z "$base_file" ]]; then
        # Only in incoming, add it
        output_section "$incoming_file"
        return
    fi
    
    # Both exist, need to merge
    local strategy=$(get_merge_strategy "$heading")
    
    case "$strategy" in
        accumulate)
            merge_accumulate "$base_file" "$incoming_file" "$heading"
            ;;
        merge_by_id)
            merge_by_id "$base_file" "$incoming_file" "$heading"
            ;;
        accumulate_unique)
            merge_accumulate_unique "$base_file" "$incoming_file" "$heading"
            ;;
        merge_entities)
            merge_entities "$base_file" "$incoming_file" "$heading"
            ;;
        latest)
            output_section "$incoming_file"
            ;;
        *)
            # Default: use incoming
            output_section "$incoming_file"
            ;;
    esac
}

output_section() {
    local section_file="$1"
    local level=$(sed -n '1p' "$section_file")
    local heading=$(sed -n '2p' "$section_file")
    
    # Output heading
    printf '%*s' "$level" '' | tr ' ' '#'
    echo " $heading"
    echo ""
    
    # Output content (skip first 2 lines which are level and heading)
    tail -n +3 "$section_file"
    echo ""
}

merge_accumulate() {
    local base_file="$1"
    local incoming_file="$2"
    local heading="$3"
    
    local level=$(sed -n '1p' "$base_file")
    
    # Output heading
    printf '%*s' "$level" '' | tr ' ' '#'
    echo " $heading"
    echo ""
    
    # Output base content
    tail -n +3 "$base_file"
    echo ""
    
    # Add incoming content with a separator comment
    echo "<!-- Merged from latest feature -->"
    echo ""
    tail -n +3 "$incoming_file"
    echo ""
}

merge_by_id() {
    local base_file="$1"
    local incoming_file="$2"
    local heading="$3"
    
    local level=$(sed -n '1p' "$base_file")
    
    # Output heading
    printf '%*s' "$level" '' | tr ' ' '#'
    echo " $heading"
    echo ""
    
    # Collect IDs from both files
    declare -A seen_ids
    
    # Output incoming items first (they override base)
    while IFS= read -r line; do
        if [[ "$line" =~ ^\-[[:space:]]\*\*(FR|NFR|AC|SC)-([0-9]+) ]]; then
            local id="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
            seen_ids["$id"]=1
        fi
        echo "$line"
    done < <(tail -n +3 "$incoming_file")
    
    # Output base items that weren't overridden
    local archived_items=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^\-[[:space:]]\*\*(FR|NFR|AC|SC)-([0-9]+) ]]; then
            local id="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
            if [[ -z "${seen_ids[$id]:-}" ]]; then
                echo "$line"
                seen_ids["$id"]=1
            else
                # Collect for archive section
                if [[ -z "$archived_items" ]]; then
                    archived_items="$line"
                else
                    archived_items="$archived_items"$'\n'"$line"
                fi
            fi
        else
            # Non-ID line, output if no ID context yet
            if [[ ${#seen_ids[@]} -eq 0 ]]; then
                echo "$line"
            fi
        fi
    done < <(tail -n +3 "$base_file")
    
    echo ""
}

merge_accumulate_unique() {
    local base_file="$1"
    local incoming_file="$2"
    local heading="$3"
    
    # Similar to merge_by_id but keeps unique items
    merge_by_id "$base_file" "$incoming_file" "$heading"
}

merge_entities() {
    local base_file="$1"
    local incoming_file="$2"
    local heading="$3"
    
    local level=$(sed -n '1p' "$incoming_file")
    
    # Output heading
    printf '%*s' "$level" '' | tr ' ' '#'
    echo " $heading"
    echo ""
    
    # For entities (data-model.md), prefer incoming but note if base had different info
    # Output incoming content
    tail -n +3 "$incoming_file"
    
    # Check if base had additional information
    if [[ -f "$base_file" ]]; then
        local base_content=$(tail -n +3 "$base_file")
        local incoming_content=$(tail -n +3 "$incoming_file")
        
        # If contents differ significantly, add a note
        if [[ "$base_content" != "$incoming_content" ]]; then
            echo ""
            echo "<!-- Previous definition archived -->"
        fi
    fi
    
    echo ""
}

# Main execution
{
    # Output preamble from incoming (has latest metadata)
    if [[ -f "$TEMP_DIR/incoming_001.txt" ]]; then
        preamble_heading=$(sed -n '2p' "$TEMP_DIR/incoming_001.txt")
        if [[ "$preamble_heading" == "PREAMBLE" ]]; then
            # Output preamble content, skipping the level and heading lines (first 2 lines)
            tail -n +3 "$TEMP_DIR/incoming_001.txt"
        fi
    fi
    
    # Merge all sections
    merge_sections
    
} > "$OUTPUT_FILE"

echo "Merge completed: $OUTPUT_FILE"

