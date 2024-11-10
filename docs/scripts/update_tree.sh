#!/bin/bash

# Get the tree output, excluding venv and node_modules
tree_output=$(tree -I 'venv|node_modules|target|archive')

# Create a temporary file with the new content
cat > docs/tree.md.tmp << EOL
# Choir-Collective Directory Structure
## Output of $ tree -I 'venv|node_modules|target|archive' | pbcopy

$tree_output
EOL

# Replace the old file with the new one
mv docs/tree.md.tmp docs/tree.md
