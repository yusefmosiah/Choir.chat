# docs/scripts/update_harmonic_vision.sh

# Use arrays for search and replace patterns
declare -a SEARCH_PATTERNS=(
    "quantum semantics"
    "quantum mechanics"
    "quantum state"
    "quantum coupling"
    "quantum coherence"
    "quantum oscillator"
)

declare -a REPLACE_PATTERNS=(
    "harmonic intelligence"
    "wave mechanics"
    "harmonic pattern"
    "harmonic coupling"
    "harmonic resonance"
    "harmonic oscillator"
)

# Header template
read -r -d '' HEADER << 'EOH'
# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.4.1"

EOH

# Process each markdown file
find docs -name "*.md" | while read -r file; do
    echo "Processing $file..."

    # Create temp file
    temp_file=$(mktemp)

    # Add header if it's a main doc file
    if [[ ! "$file" =~ "level" && ! "$file" =~ "scripts" ]]; then
        echo "$HEADER" > "$temp_file"
        cat "$file" >> "$temp_file"
    else
        cat "$file" > "$temp_file"
    fi

    # Update terminology
    for i in "${!SEARCH_PATTERNS[@]}"; do
        sed -i '' "s/${SEARCH_PATTERNS[$i]}/${REPLACE_PATTERNS[$i]}/g" "$temp_file"
    done

    # Move temp file back
    mv "$temp_file" "$file"
done

echo "Documentation updated to reflect Harmonic Intelligence vision"
