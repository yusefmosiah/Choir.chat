#!/bin/bash

# Get the tree output, excluding venv and node_modules
tree_output=$(tree -I 'venv|archive|__pycache__|iOS_Example|dependencies')

# Create a temporary file with the new content
cat > docs/tree.md.tmp << EOL
# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example|dependencies' | pbcopy

$tree_output
EOL

# Replace the old file with the new one
mv docs/tree.md.tmp docs/tree.md
