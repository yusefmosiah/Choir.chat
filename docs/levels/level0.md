# Level 0 Documentation



=== File: docs/tree.md ===



==
tree.md
==


# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example|dependencies' | pbcopy

.
├── Choir
│   ├── App
│   │   └── ChoirApp.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── Contents.json
│   │   │   └── Icon-App-1024x1024@2x.png
│   │   ├── Contents.json
│   │   └── Icon-App-1024x1024.imageset
│   │       ├── Contents.json
│   │       └── Icon-App-1024x1024@2x.png
│   ├── Choir.entitlements
│   ├── ContentView.swift
│   ├── Coordinators
│   │   └── RESTPostchainCoordinator.swift
│   ├── Info.plist
│   ├── Models
│   │   └── ChoirModels.swift
│   ├── Networking
│   │   └── PostchainAPIClient.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Protocols
│   │   └── PostchainCoordinator.swift
│   ├── Services
│   │   ├── KeychainService.swift
│   │   └── WalletManager.swift
│   ├── ViewModels
│   │   └── PostchainViewModel.swift
│   ├── Views
│   │   ├── ChoirThreadDetailView.swift
│   │   ├── MessageRow.swift
│   │   ├── PostchainView.swift
│   │   ├── Thread
│   │   │   └── Components
│   │   │       ├── ThreadInputBar.swift
│   │   │       └── ThreadMessageList.swift
│   │   └── WalletView.swift
│   └── actor_model
│       └── phase_worker_pool.py
├── Choir.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       ├── Package.resolved
│   │   │       └── configuration
│   │   └── xcuserdata
│   │       └── wiz.xcuserdatad
│   │           ├── IDEFindNavigatorScopes.plist
│   │           └── UserInterfaceState.xcuserstate
│   └── xcuserdata
│       └── wiz.xcuserdatad
│           ├── xcdebugger
│           │   └── Breakpoints_v2.xcbkptlist
│           └── xcschemes
│               └── xcschememanagement.plist
├── ChoirTests
│   ├── APIResponseTests.swift
│   ├── ChoirTests.swift
│   ├── ChoirThreadTests.swift
│   └── PostchainAPIClientTests.swift
├── ChoirUITests
│   ├── ChoirUITests.swift
│   └── ChoirUITestsLaunchTests.swift
├── api
│   ├── Dockerfile
│   ├── __init__.py
│   ├── app
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── langchain_utils.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── postchain
│   │   │   ├── __init__.py
│   │   │   ├── checkpointer.py
│   │   │   ├── nodes
│   │   │   ├── prompts
│   │   │   ├── schemas
│   │   │   │   ├── __init__.py
│   │   │   │   └── state.py
│   │   │   ├── simple_graph.py
│   │   │   ├── state
│   │   │   ├── state_manager.py
│   │   │   └── utils.py
│   │   ├── routers
│   │   │   ├── balance.py
│   │   │   ├── postchain.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   └── vectors.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   ├── chorus.py
│   │   │   └── sui_service.py
│   │   ├── thespian
│   │   │   └── hello.py
│   │   ├── tools
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   ├── brave_search.py
│   │   │   ├── calculator.py
│   │   │   ├── conversation.py
│   │   │   ├── duckduckgo_search.py
│   │   │   ├── qdrant.py
│   │   │   ├── qdrant_workflow.py
│   │   │   ├── tavily_search.py
│   │   │   └── web_search.py
│   │   └── utils.py
│   ├── custom_state_manager_test.log
│   ├── debug_stream_content.log
│   ├── main.py
│   ├── postchain_memory_debug.log
│   ├── postchain_tests.log
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
│   ├── run_tests.sh
│   └── tests
│       ├── __init__.py
│       ├── conftest.py
│       ├── postchain
│       │   ├── __init__.py
│       │   ├── analysis.py
│       │   ├── random_gen_prompts.md
│       │   ├── run_all_tests.py
│       │   ├── run_tests.py
│       │   ├── test_cases.json
│       │   ├── test_cases.py
│       │   ├── test_framework.py
│       │   ├── test_langgraph_multiturn.py
│       │   ├── test_langgraph_multiturn_abstracted.py
│       │   ├── test_multiturn.py
│       │   ├── test_providers.py
│       │   ├── test_providers_abstracted.py
│       │   ├── test_random_multimodel.py
│       │   ├── test_random_multimodel_stream.py
│       │   ├── test_simple_multimodel.py
│       │   ├── test_simple_multimodel_stream.py
│       │   ├── test_stream.py
│       │   ├── test_structured_output.py
│       │   ├── test_tool_multimodel.py
│       │   ├── test_tool_random_multimodel.py
│       │   └── test_utils.py
│       ├── test_main.py
│       ├── test_sui_service.py
│       ├── test_user_thread_endpoints.py
│       ├── thespian
│       │   └── test_hello.py
│       └── tools
│           ├── __init__.py
│           ├── direct_search_diagnostic.py
│           ├── direct_search_test.py
│           ├── haiku_search_test.py
│           ├── langgraph_test.py
│           ├── run_tool_tests.py
│           ├── test_anthropic_langgraph.py
│           ├── test_brave_search.py
│           ├── test_calculator.py
│           ├── test_duckduckgo_search.py
│           ├── test_langgraph_providers_tools.py
│           ├── test_multimodel_with_tools.py
│           ├── test_provider_langgraph.py
│           ├── test_qdrant.py
│           ├── test_qdrant_multimodel.py
│           ├── test_qdrant_workflow.py
│           ├── test_recent_events.py
│           ├── test_search_tools_report.py
│           ├── test_tavily_search.py
│           └── test_updated_search.py
├── choir_coin
│   └── choir_coin
│       ├── Move.lock
│       ├── Move.toml
│       ├── build
│       │   └── choir
│       │       ├── BuildInfo.yaml
│       │       ├── bytecode_modules
│       │       │   ├── choir.mv
│       │       │   └── choir_tests.mv
│       │       ├── source_maps
│       │       │   ├── choir.json
│       │       │   ├── choir.mvsm
│       │       │   ├── choir_tests.json
│       │       │   └── choir_tests.mvsm
│       │       └── sources
│       │           ├── choir.move
│       │           └── choir_tests.move
│       ├── sources
│       │   └── choir_coin.move
│       └── tests
│           └── choir_coin_tests.move
├── docker-compose.yml
├── docs
│   ├── 1-concepts
│   │   ├── actor_model_overview.md
│   │   ├── postchain_actor_model.md
│   │   ├── postchain_conceptual_model.md
│   │   ├── postchain_temporal_logic.md
│   │   └── scale_free_actor_architecture.md
│   ├── 2-architecture
│   │   ├── actor_hierarchy_diagram.md
│   │   ├── actor_system_diagram.md
│   │   ├── architecture_integration.md
│   │   ├── message_flow_diagrams.md
│   │   ├── phase_worker_pool.md
│   │   ├── state_management_overview.md
│   │   ├── thread_contract_model.md
│   │   └── token_economy_model.md
│   ├── 3-implementation
│   │   ├── actor_debugging_guide.md
│   │   ├── actor_implementation_guide.md
│   │   ├── actor_testing_guide.md
│   │   ├── developer_quickstart.md
│   │   ├── message_protocol_reference.md
│   │   ├── phase_requirements
│   │   │   ├── action_phase.md
│   │   │   ├── experience_phase.md
│   │   │   ├── intention_phase.md
│   │   │   ├── observation_phase.md
│   │   │   ├── phase_requirements_index.md
│   │   │   ├── understanding_phase.md
│   │   │   └── yield_phase.md
│   │   └── state_management_patterns.md
│   ├── 4-integration
│   │   ├── blockchain_integration.md
│   │   ├── identity_service.md
│   │   └── libsql_integration.md
│   ├── 5-operations
│   │   ├── deployment_guide.md
│   │   ├── monitoring_observability.md
│   │   └── testing_strategy.md
│   ├── 6-business
│   │   ├── anonymity_by_default.md
│   │   ├── business_model.md
│   │   └── evolution_token.md
│   ├── CHANGELOG.md
│   ├── README.md
│   ├── architecture_reorganization_plan_mcp.md
│   ├── comp_provider_info.md
│   ├── core_core.md
│   ├── core_economics.md
│   ├── core_state_transitions.md
│   ├── data_engine_model.md
│   ├── documentation_index.md
│   ├── e_business.md
│   ├── e_concept.md
│   ├── evolution_naming.md
│   ├── evolution_stack.md
│   ├── evolution_token.md
│   ├── fqaho_simulation.md
│   ├── fqaho_visualization.md
│   ├── index.md
│   ├── levels
│   │   ├── all.txt
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   └── level5.md
│   ├── phase_worker_pool_architecture.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_identity_as_a_service.md
│   ├── plan_libsql.md
│   ├── postchain_actor_model.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   ├── reorganization_script_design.md
│   │   └── update_tree.sh
│   ├── security_considerations.md
│   ├── stack_argument.md
│   ├── stack_pivot_summary.md
│   └── tree.md
├── examples
│   └── phase_worker_pool_demo.py
├── notebooks
│   ├── fqaho_simulation.ipynb
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── render.yaml
└── scripts
    ├── generate_provider_reports.sh
    ├── generate_quick_search_report.sh
    ├── generate_search_report.sh
    └── generate_single_provider_report.sh

70 directories, 224 files

=== File: docs/CHANGELOG.md ===



==
CHANGELOG.md
==


# Changelog

## [Unreleased] - 2025-03-12

### Changed

- Major architectural pivot: Shifted from LangGraph to MCP Architecture
  - Transitioned to Model Context Protocol (MCP) architecture
  - Added libSQL/Turso for combined SQL+vector storage
  - Integrated PySUI for blockchain operations
  - Established Docker+Phala deployment pipeline
  - Preserved FQAHO economic model intact

### Added

- Defined new coherent technology stack:

  - Model Context Protocol (MCP) architecture: Service-oriented architecture for phases
  - libSQL/Turso: Combined SQL+vector database for state and RAG
  - PySUI: Blockchain integration for tokenomics and citations
  - Pydantic: Type safety for message passing between services
  - FastAPI/Uvicorn: High-performance async API layer
  - Docker: Containerization for deployment
  - Phala Network: Privacy-preserving computation platform for deployment

- Extended the Post Chain with Phase Worker Pool pattern:
  - Phases are now implemented as MCP servers (not just single instances)
  - Server implementations can be specialized by modality (text, audio, video, code)
  - Worker Pool pattern abstracts AI models from server implementations
  - Support for specialized domain servers (medical, legal, financial)

### Removed

- Deprecated LangGraph dependency due to persistent memory management issues
- Simplified architecture by eliminating graph-based state management complexities

## [2025-02-25] - 2025-02-25

### Added

- Implemented UI carousel to improve user experience
- Added display of priors in the Experience step
- Resumed active development after coding hiatus

### Planned

- API streaming implementation to enhance responsiveness
- Model reconfiguration for improved performance
- Go multimodel, then multimodal
- OpenRouter integration
- Conceptual evolution from "Chorus Cycle" to "Post Chain"
  - Representing shift from harmonic oscillator (cycle) to anharmonic oscillator (chain)
  - Aligning interface terminology with underlying FQAHO model
- Client-side editable system prompts for customization
- Additional phases in the Post Chain:
  - Web search phase for real-time information access
  - Sandboxed arbitrary tool use phase for enhanced capabilities

## [2025-02-24] - 2025-02-24

### Changed

- Implemented fractional quantum anharmonic oscillator model for dynamic stake pricing
- Added fractional parameter α to capture memory effects and non-local interactions
- Revised parameter modulation formulas for K₀, α, and m to reflect interdependencies
- Created simulation framework for parameter optimization

## [2025-02-23] - 2025-02-23

### Changed

- Documented quantum anharmonic oscillator model implementation and dynamic stake pricing mechanism via an effective anharmonic coefficient modulated by approval/refusal statistics.

## [Unreleased]

### Changed

- Updated all documentation to version 6.0
  - Transformed structured documentation into fluid prose
  - Relaxed event-driven architecture requirements for initial TestFlight
  - Clarified implementation priorities and post-funding features
  - Maintained theoretical frameworks while focusing on core functionality

### Added

- Initial Chorus cycle working in iOS simulator
  - Basic message flow through phases
  - Response handling
  - State management

### Documented

- Created 15 comprehensive issues covering:
  - Core message system implementation
  - Type reconciliation with Qdrant
  - API client updates
  - Coordinator message flow
  - User identity management
  - Thread state management
  - Integration testing
  - Error handling strategy
  - Performance monitoring
  - State recovery
  - Thread sheet implementation
  - Thread contract implementation
  - Message rewards system
  - LanceDB migration
  - Citation visualization

### Architecture

- Defined clear type system for messages
- Planned migration to LanceDB
- Structured multimodal support strategy

### Technical Debt

- Identified areas needing more specification:
  - Thread Sheet UI (marked as "AI SLOP")
  - Reward formulas need verification
  - Migration pipeline needs careful implementation

## [0.4.2] - 2024-11-09

### Added

- Development principles with focus on groundedness
- Basic chat interface implementation
- SwiftData message persistence
- Initial Action step foundation

### Changed

- Shifted to iterative, ground-up development approach
- Simplified initial implementation scope
- Focused on working software over theoretical architecture
- Adopted step-by-step Chorus Cycle implementation strategy

### Principles

- Established groundedness as core development principle
- Emphasized iterative growth and natural evolution
- Prioritized practical progress over theoretical completeness
- Introduced flexible, evidence-based development flow

## [0.4.1] - 2024-11-08

### Added

- Self-creation process
- Post-training concepts
- Concurrent processing ideas
- Democratic framing
- Thoughtspace visualization

### Changed

- Renamed Update to Understanding
- Enhanced step descriptions
- Refined documentation focus
- Improved pattern recognition

## [0.4.0] - 2024-10-30

### Added

- Swift architecture plans
- Frontend-driven design
- Service layer concepts
- Chorus cycle definition

### Changed

- Enhanced system architecture
- Refined core patterns

## [0.3.5] - 2024-09-01

- Choir.chat as a web3 dapp
- messed around with solana
- used a lot of time messing with next.js/react/typescript/javascript
- recognized that browser extension wallet is terrible ux

## [0.3.0] - 2024-03-01

### Added

- ChoirGPT development from winter 2023 to spring 2024

- First developed as a ChatGPT plugin, then a Custom GPT
- The first global RAG system / collective intelligence as a GPT

## [0.2.10] - 2023-04-01

### Added

- Ahpta development from winter 2022 to spring 2023

## [0.2.9] - 2022-04-01

### Added

- V10 development from fall 2021 to winter 2022

## [0.2.8] - 2021-04-01

### Added

- Elevisio development from spring 2020 to spring 2021

## [0.2.7] - 2020-04-01

### Added

- Bluem development from spring 2019 to spring 2020

## [0.2.6] - 2019-04-01

### Added

- Blocstar development from fall 2018 to spring 2019

## [0.2.5] - 2018-04-01

### Added

- Phase4word development from summer 2017 to spring 2018

### Changed

- Showed Phase4word to ~50 people in spring 2018, received critical feedback
- Codebase remains in 2018 vintage

## [0.2.0] - 2016-06-20

### Added

- Phase4 party concept
- Early democracy technology
- Initial value systems

### Changed

- Moved beyond truth measurement framing
- Refined core concepts

## [0.1.0] - 2015-07-15

### Added

- Initial simulation hypothesis insight
- "Kandor"
- Quantum information concepts
- Planetary coherence vision
- Core system ideas

=== File: docs/scripts/combiner.sh ===



==
combiner.sh
==


#!/bin/bash

# Revised prefix arrays
level0_prefixes=("")  # Basic technical integration
level1_prefixes=("core")  # Core system components
level2_prefixes=("e")           # Business/concept/implementation
level3_prefixes=("plan")               # State/economic models
level4_prefixes=("fqaho")     # Simulations
level5_prefixes=("evolution" "data")             # Foundational principles

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

    SPECIAL_FILES=("docs/prompt_wake_up.md" "docs/prompt_getting_started.md" "docs/prompt_reentry.md" "docs/prompt_organization.md" "docs/prompt_summary_prompt.md" "docs/prompt_chorus_cycle.md" "docs/tree.md" "docs/CHANGELOG.md" "docs/scripts/combiner.sh")

    # Level 0 now includes important system files (previously in level -1)
    if [ "$level" -eq 0 ]; then
        # Add system files (previously in level -1)
        for special_file in "${SPECIAL_FILES[@]}"; do
            if [ -f "$special_file" ]; then
                echo -e "\n=== File: $special_file ===\n" >> "$output_file"
                add_separator "$(basename "$special_file")" >> "$output_file"
                cat "$special_file" >> "$output_file"
                echo "$special_file" >> "/tmp/processed_files.txt"
            fi
        done

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

# Process all levels (excluding level -1 as its content is now in level 0)
echo "Processing documentation..."
for level in {0..5}; do
    process_level $level
done

# Concatenate all levels into a single file
echo "Combining all levels into one file..."
mkdir -p docs/levels
cat docs/levels/level{0..5}.md > docs/levels/all.txt

# Check for uncategorized files
echo -e "\nUncategorized files:"
uncategorized=0
for doc in docs/*.md; do
    if ! grep -q "^$doc$" "/tmp/processed_files.txt"; then
        echo "$doc"
        uncategorized=$((uncategorized + 1))
        # Append uncategorized files to all.txt
        echo -e "\n=== File: $doc ===\n" >> docs/levels/all.txt
        add_separator "$(basename "$doc" .md)" >> docs/levels/all.txt
        cat "$doc" >> docs/levels/all.txt
    fi
done

if [ "$uncategorized" -gt 0 ]; then
    echo -e "\nTotal uncategorized: $uncategorized files"
fi

# Cleanup
rm -f "/tmp/processed_files.txt"

echo "Documentation combination complete"
