# Documentation Reorganization Script Design

This document outlines the design for a script that would help reorganize the Choir documentation according to the architectural pivot plan.

## Script Purpose

The reorganization script would automate the process of:
1. Creating the new directory structure
2. Moving and renaming relevant files to the new structure
3. Updating internal links within documents
4. Creating placeholders for planned documents
5. Generating reports of what has been moved and what still needs attention

## Directory Structure Creation

The script would create the following directory structure:

```bash
# Create main documentation directories
mkdir -p docs/1-concepts
mkdir -p docs/2-architecture
mkdir -p docs/3-implementation
mkdir -p docs/4-integration
mkdir -p docs/5-operations
mkdir -p docs/6-business
mkdir -p docs/archive/langgraph
```

## File Moving Logic

The script would move files according to predefined rules:

```bash
# Examples of file moving commands
# Core concepts
mv docs/postchain_actor_model.md docs/1-concepts/
mv docs/fqaho_visualization.md docs/1-concepts/
mv docs/core_economics.md docs/1-concepts/
mv docs/core_state_transitions.md docs/1-concepts/
mv docs/evolution_naming.md docs/1-concepts/

# Architecture documents
mv docs/stack_argument.md docs/2-architecture/
mv docs/phase_worker_pool_architecture.md docs/2-architecture/
mv docs/security_considerations.md docs/2-architecture/

# Implementation documents
mv docs/migration_langgraph_to_actor.md docs/3-implementation/

# Integration documents
mv docs/plan_libsql.md docs/4-integration/
mv docs/plan_identity_as_a_service.md docs/4-integration/

# Business documents
mv docs/e_business.md docs/6-business/
mv docs/evolution_token.md docs/6-business/
mv docs/plan_anonymity_by_default.md docs/6-business/
```

## Placeholder Creation

For documents identified in the plan but not yet created, the script would generate placeholders:

```bash
# Create placeholder files with basic structure
for file in "docs/3-implementation/message_protocol_reference.md" "docs/3-implementation/state_management_patterns.md" "docs/5-operations/deployment_guide.md" "docs/5-operations/testing_strategy.md" "docs/5-operations/monitoring_observability.md" "docs/4-integration/blockchain_integration.md"; do
  echo "# $(basename "$file" .md | tr '_' ' ' | sed -e 's/\b\(.\)/\u\1/g')" > "$file"
  echo "" >> "$file"
  echo "This document is a placeholder for future content. It will be developed according to the [Architecture Reorganization Plan](../architecture_reorganization_plan.md)." >> "$file"
  echo "" >> "$file"
  echo "## Planned Sections" >> "$file"
  echo "" >> "$file"
  echo "1. Introduction" >> "$file"
  echo "2. Key Concepts" >> "$file"
  echo "3. Implementation Guidelines" >> "$file"
  echo "4. Examples" >> "$file"
  echo "5. Best Practices" >> "$file"
done
```

## Link Updating Logic

The script would need to update internal document links to maintain consistency:

```bash
# Example of link updating logic (pseudocode)
# For each markdown file:
#   Find all markdown links
#   Check if the linked file has been moved
#   If yes, update the link path
```

## Archive Logic

For outdated LangGraph documents that should be preserved for reference:

```bash
# Move LangGraph-specific documentation to archive
find docs -name "*langgraph*.md" -not -path "*/archive/*" -exec mv {} docs/archive/langgraph/ \;
```

## Report Generation

The script would generate a summary report:

```bash
# Create a migration report
echo "# Documentation Reorganization Report" > docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
echo "Generated on: $(date)" >> docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
echo "## Files Moved" >> docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
# List moved files

echo "" >> docs/reorganization_report.md
echo "## Placeholders Created" >> docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
# List placeholder files

echo "" >> docs/reorganization_report.md
echo "## Links Updated" >> docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
# Report on link changes

echo "" >> docs/reorganization_report.md
echo "## Manual Actions Required" >> docs/reorganization_report.md
echo "" >> docs/reorganization_report.md
# List files needing manual review
```

## Implementation Notes

When implementing this script, consider:

1. **Backup**: Always create a backup of the documentation first
2. **Testing**: Test with a copy of the documentation before running on actual files
3. **Error Handling**: Include proper error checking and reporting
4. **Verification**: Add verification steps to ensure links and references remain valid
5. **Interactive Mode**: Consider adding an interactive confirmation option for critical operations

## Script Execution

The script would be executed by a developer with appropriate permissions:

```bash
# To execute the script (after review and approval):
cd /Users/wiz/Choir
./docs/scripts/reorganize_docs.sh
```

## Implementation Recommendation

This script should be implemented by someone in Code mode, as it involves file system operations that require more permissions than what's available in Architect mode. The actual implementation should include proper error handling, dry-run options, and backup mechanisms to ensure documentation isn't lost in the transition.
