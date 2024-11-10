#!/bin/bash
# docs/scripts/archive_web_stack.sh

set -x  # Enable debug output

# Create archive directory structure
echo "Creating archive directories..."
mkdir -p ../archive/{ui_components,state_management,api_integration,deployment}
touch ../archive/swift_todos.md
touch ../archive/archive_log.md

# Web stack patterns - expanded
WEB_PATTERNS=(
    "React"
    "Next.js"
    "TypeScript"
    "JavaScript"
    "useEffect"
    "useState"
    "Component"
    "tsx"
    "tailwind"
    "frontend"
    "AIResponse"
    "ChoirChat"
    "ChorusPanel"
)

echo "Searching for web stack files..."
# Process each markdown file
find .. -type f -name "*.md" | while read -r file; do
    echo "Checking $file"
    # Check if file contains web stack references
    for pattern in "${WEB_PATTERNS[@]}"; do
        if grep -i -q "$pattern" "$file"; then
            filename=$(basename "$file")
            echo "Found web stack reference in $filename: $pattern"

            # Determine category based on filename
            category="uncategorized"
            case "$filename" in
                *AIResponse* | *ChoirChat* | *ChorusPanel* | *UserInput*)
                    category="ui_components"
                    echo "ui_components:SwiftUI replacement needed for $filename" >> ../archive/swift_todos.md
                    ;;
                *Frontend*)
                    category="ui_components"
                    echo "ui_components:SwiftUI architecture needed for $filename" >> ../archive/swift_todos.md
                    ;;
                *Implementation*)
                    category="api_integration"
                    echo "api_integration:Swift client needed for $filename" >> ../archive/swift_todos.md
                    ;;
            esac

            # Move file to archive
            echo "Moving $filename to $category"
            mv "$file" "../archive/$category/$filename"
            echo "Archived $filename to $category - $(date)" >> ../archive/archive_log.md
            break
        fi
    done
done

# Generate summary
echo "# Swift Documentation Needed" > ../archive/swift_roadmap.md
sort -u ../archive/swift_todos.md >> ../archive/swift_roadmap.md

echo "Archive process complete"
