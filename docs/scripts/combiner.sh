#!/bin/bash

# Revised prefix arrays
level0_prefixes=("client" "sui" "proxy" "carousel" "distributed")  # Basic technical integration
level1_prefixes=("core" "Tech" "Dev" "Service" "Coordinator")  # Core system components
level2_prefixes=("e" "reward" "Error" "Impl")           # Business/concept/implementation
level3_prefixes=("plan" "state" "economic" "vector" "chain")               # State/economic models
level4_prefixes=("evolution" "theory" "Model" "Emergence" "anonymity")     # Theoretical frameworks
level5_prefixes=("data" "harmonic" "language" "law" "quantum")             # Foundational principles

# Function to add separator and header
add_separator() {
    echo -e "\n"
    echo "=="
    echo "$1"
    echo "=="
    echo -e "\n"
}

# Function to get level for a file
get_level_for_file() {
    filename=$(basename "$1")
    prefix=$(echo "$filename" | cut -d'_' -f1)

    for p in "${level0_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 0 && return; done
    for p in "${level1_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 1 && return; done
    for p in "${level2_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 2 && return; done
    for p in "${level3_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 3 && return; done
    for p in "${level4_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 4 && return; done
    for p in "${level5_prefixes[@]}"; do [[ "$prefix" == "$p" ]] && echo 5 && return; done

    echo -1
}

# Function to process files for a level
process_level() {
    level=$1
    output_file="docs/levels/level${level}.md"

    echo "# Level ${level} Documentation" > "$output_file"
    echo -e "\n" >> "$output_file"

    SPECIAL_FILES=("docs/prompt_wake_up.md" "docs/prompt_getting_started.md" "docs/prompt_reentry.md" "docs/prompt_organization.md" "docs/prompt_summary_prompt.md" "docs/prompt_chorus_cycle.md" "docs/tree.md" "docs/CHANGELOG.md")

    # Special handling for level -1 (system files)
    if [ "$level" -eq -1 ]; then
        for special_file in "${SPECIAL_FILES[@]}"; do
            if [ -f "$special_file" ]; then
                echo -e "\n=== File: $special_file ===\n" >> "$output_file"
                add_separator "$(basename "$special_file")" >> "$output_file"
                cat "$special_file" >> "$output_file"
                echo "$special_file" >> "/tmp/processed_files.txt"
            fi
        done
        return
    fi

    # Special handling for level 0 (include issues)
    if [ "$level" -eq 0 ]; then
        # Process issues first
        if [ -d "docs/issues" ]; then
            for issue in docs/issues/issue_*.md; do
                if [ -f "$issue" ]; then
                    echo -e "\n=== File: $issue ===\n" >> "$output_file"
                    add_separator "$(basename "$issue" .md)" >> "$output_file"
                    cat "$issue" >> "$output_file"
                    echo "$issue" >> "/tmp/processed_files.txt"
                fi
            done
        fi
    fi

    # Process all docs to find ones for this level
    for file in docs/*.md; do
        if [ -f "$file" ] && [ "$(get_level_for_file "$file")" -eq "$level" ]; then
            echo -e "\n=== File: $file ===\n" >> "$output_file"
            add_separator "$(basename "$file" .md)" >> "$output_file"
            cat "$file" >> "$output_file"
            echo "$file" >> "/tmp/processed_files.txt"
        fi
    done
}

# Create temporary file for tracking
touch /tmp/processed_files.txt

# Process all levels
echo "Processing documentation..."
process_level -1
for level in {0..5}; do
    process_level $level
done

# Concatenate all levels into a single file
echo "Combining all levels into one file..."
mkdir -p docs/levels
cat docs/levels/level-1.md docs/levels/level{0..5}.md > docs/levels/all.txt

# Check for uncategorized files
echo -e "\nUncategorized files:"
uncategorized=0
for doc in docs/*.md; do
    if ! grep -q "^$doc$" "/tmp/processed_files.txt"; then
        echo "$doc"
        uncategorized=$((uncategorized + 1))
    fi
done

if [ "$uncategorized" -gt 0 ]; then
    echo -e "\nTotal uncategorized: $uncategorized files"
fi

# Cleanup
rm -f "/tmp/processed_files.txt"

echo "Documentation combination complete"
