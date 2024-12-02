#!/bin/bash

set -e

check_commands() {
    for cmd in gh git grep jq; do
        command -v "$cmd" &> /dev/null || { echo "Error: $cmd not installed"; exit 1; }
    done
}

check_github_auth() {
    gh auth status &> /dev/null || { echo "Error: Run 'gh auth login' first"; exit 1; }
}

fetch_repos() {
    local repos_file="repos.txt"
    [ -f "$repos_file" ] && cat "$repos_file" || {
        gh repo list "$1" --json nameWithOwner --limit 1000 | jq -r '.[].nameWithOwner' > "$repos_file"
        cat "$repos_file"
    }
}

process_matches() {
    local repo="$1"
    local file="$2"
    local line="$3"
    local content="$4"
    local search_string="$5"
    
    # Safely escape content for JSON
    content=$(echo "$content" | jq -Rs .)
    file=$(echo "$file" | jq -Rs .)
    repo=$(echo "$repo" | jq -Rs .)
    search_string=$(echo "$search_string" | jq -Rs .)
    
    # Find position using awk for better handling of special characters
    local char_pos
    char_pos=$(echo "$content" | awk -v pat="$search_string" '{
        p = index($0, pat)
        if (p > 0) print p
        else print 1
    }')
    
    printf '{"repo":%s,"file":%s,"line":%d,"position":%d,"pattern":%s,"content":%s}\n' \
        "$repo" "$file" "$line" "$char_pos" "$search_string" "$content"
}

process_repo() {
    local repo="$1"
    local repo_dir="./repos/$(basename "$repo")"

    echo "Processing: $repo"
    mkdir -p "$repo_dir"

    if [ ! -d "$repo_dir/.git" ]; then
        gh repo clone "$repo" "$repo_dir" 2>/dev/null || {
            echo "Warning: Failed to clone $repo, skipping..."
            return
        }
    fi

    cd "$repo_dir" || return

    while IFS= read -r search_string || [ -n "$search_string" ]; do
        [ -z "$search_string" ] && continue
        echo "  Searching for: $search_string"
        
        git grep -IEHn "$search_string" 2>/dev/null | while IFS=: read -r file line content; do
            process_matches "$repo" "$file" "$line" "$content" "$search_string" >> "$TEMP_FILE"
        done || true
    done < "$WORK_DIR/$STRINGS_FILE"

    cd "$WORK_DIR" || exit 1
}

generate_summary() {
    local results_file="$1"
    local summary_file="${results_file%.*}_summary.json"
    
    if [ -s "$results_file" ]; then
        jq -c '
            group_by(.repo) | map({
                repository: .[0].repo,
                total_matches: length,
                unique_files: ([.[].file] | unique | length),
                matches: map({
                    file: .file,
                    matches: [{line: .line, position: .position, pattern: .pattern, content: .content}]
                }) | group_by(.file) | map({
                    file: .[0].file,
                    match_count: length,
                    matches: [.[].matches[]] | sort_by(.line)
                })
            })
        ' "$results_file" > "$summary_file"
        
        echo "Summary generated in: $summary_file"
    fi
}

main() {
    [ $# -lt 2 ] && { echo "Usage: $0 <organization-name> <strings-file> [output-file]"; exit 1; }

    export ORG_NAME="$1"
    export STRINGS_FILE="$2"
    export OUTPUT_FILE="${3:-results.json}"
    export WORK_DIR="$(pwd)"
    export TEMP_FILE=$(mktemp)

    [ ! -f "$STRINGS_FILE" ] && { echo "Error: Strings file not found"; exit 1; }

    check_commands
    check_github_auth

    echo "Starting search..."
    echo "Organization: $ORG_NAME"
    echo "Strings file: $STRINGS_FILE"
    echo "Output file: $OUTPUT_FILE"

    REPOS=$(fetch_repos "$ORG_NAME") || { echo "Error: No repositories found"; exit 1; }
    
    # Initialize files
    echo "[]" > "$OUTPUT_FILE"
    : > "$TEMP_FILE"
    
    echo "$REPOS" | while read -r repo; do
        process_repo "$repo"
    done

    if [ -s "$TEMP_FILE" ]; then
        jq -s '.' "$TEMP_FILE" > "$OUTPUT_FILE"
        generate_summary "$OUTPUT_FILE"
    else
        echo "No matches found"
    fi

    rm -f "$TEMP_FILE"
    echo "Search completed!"
}

main "$@"