# Level 0 Documentation



=== File: docs/tree.md ===



==
tree.md
==


# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example|dependencies' | pbcopy

.
├── CLAUDE.md
├── Choir
│   ├── App
│   │   ├── AppDelegate.swift
│   │   ├── BackgroundStateMonitor.swift
│   │   └── ChoirApp.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── Contents.json
│   │   │   └── Icon-App-1024x1024@2x.png
│   │   ├── Contents.json
│   │   ├── Icon-App-1024x1024.imageset
│   │   │   ├── Contents.json
│   │   │   └── Icon-App-1024x1024@2x.png
│   │   └── choir-logo.imageset
│   │       └── Contents.json
│   ├── Choir.entitlements
│   ├── Config
│   │   └── ApiConfig.swift
│   ├── ContentView.swift
│   ├── Coordinators
│   │   ├── AppCoordinator.swift
│   │   ├── PostchainCoordinator.swift
│   │   └── PostchainCoordinatorImpl.swift
│   ├── Documentation
│   │   └── DesignStyleGuide.md
│   ├── Extensions
│   ├── Info.plist
│   ├── Models
│   │   ├── APITypes.swift
│   │   ├── AnyCodable.swift
│   │   ├── AuthModels.swift
│   │   ├── CoinType.swift
│   │   ├── ConversationModels.swift
│   │   ├── NotificationModels.swift
│   │   ├── PostchainStreamEvent+Extension.swift
│   │   ├── SearchModels.swift
│   │   └── WalletBalance.swift
│   ├── Networking
│   │   ├── EventSource.swift
│   │   ├── PostchainAPIClient.swift
│   │   └── RewardsService.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Services
│   │   ├── APIClient.swift
│   │   ├── AuthService.swift
│   │   ├── BackgroundTaskManager.swift
│   │   ├── KeychainService.swift
│   │   ├── ModelConfigManager.swift
│   │   ├── PushNotificationManager.swift
│   │   ├── ThreadManager.swift
│   │   ├── ThreadPersistenceService.swift
│   │   ├── TransactionService.swift
│   │   ├── VectorService.swift
│   │   └── WalletManager.swift
│   ├── Utils
│   │   ├── MarkdownPaginator.swift
│   │   ├── MarkdownThemes.swift
│   │   ├── PaginationCacheManager.swift
│   │   ├── PaginationUtils.swift
│   │   ├── String+Extensions.swift
│   │   ├── TextSelectionSheet.swift
│   │   └── UIDevice+Extensions.swift
│   ├── ViewModels
│   │   └── PostchainViewModel.swift
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── Components
│       ├── EnhancedSendCoinView.swift
│       ├── GlassPageControl.swift
│       ├── ImportMnemonicView.swift
│       ├── LoginView.swift
│       ├── MessageRow.swift
│       ├── ModelConfigView.swift
│       ├── OnboardingView.swift
│       ├── PaginatedMarkdownView.swift
│       ├── PhaseCard.swift
│       ├── PhaseCardContextMenu.swift
│       ├── PostchainView.swift
│       ├── QRScannerView.swift
│       ├── SettingsView.swift
│       ├── Styles
│       ├── Thread
│       │   └── Components
│       │       ├── ThreadInputBar.swift
│       │       └── ThreadMessageList.swift
│       ├── ThreadExportView.swift
│       ├── ThreadImportView.swift
│       ├── TransactionsView.swift
│       ├── WalletCardView.swift
│       ├── WalletSelectionView.swift
│       └── WalletView.swift
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
│   └── RESTPostchainAPIClientTests.swift
├── ChoirUITests
│   ├── ChoirUITests.swift
│   └── ChoirUITestsLaunchTests.swift
├── README.md
├── api
│   ├── Dockerfile
│   ├── __init__.py
│   ├── app
│   │   ├── __init__.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── langchain_utils.py
│   │   ├── middleware
│   │   │   ├── __init__.py
│   │   │   └── auth.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   ├── api.py
│   │   │   ├── auth.py
│   │   │   └── user.py
│   │   ├── postchain
│   │   │   ├── README.md
│   │   │   ├── __init__.py
│   │   │   ├── langchain_workflow.py
│   │   │   ├── phases
│   │   │   ├── postchain_llm.py
│   │   │   ├── prompts
│   │   │   │   └── prompts.py
│   │   │   ├── schemas
│   │   │   │   ├── __init__.py
│   │   │   │   ├── rewards.py
│   │   │   │   └── state.py
│   │   │   ├── state
│   │   │   └── utils.py
│   │   ├── routers
│   │   │   ├── auth.py
│   │   │   ├── balance.py
│   │   │   ├── notifications.py
│   │   │   ├── postchain.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   └── vectors.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   ├── auth_service.py
│   │   │   ├── notification_service.py
│   │   │   ├── push_notification_service.py
│   │   │   ├── rewards_service.py
│   │   │   └── sui_service.py
│   │   ├── tools
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   ├── brave_search.py
│   │   │   ├── calculator.py
│   │   │   ├── qdrant.py
│   │   │   ├── tavily_search.py
│   │   │   └── web_search.py
│   │   └── utils.py
│   ├── blog
│   │   ├── business_model.md
│   │   ├── inverse_scaling_law.md
│   │   └── loop_of_thought.md
│   ├── content
│   │   ├── landing.md
│   │   ├── marketing.md
│   │   ├── privacy.md
│   │   └── support.md
│   ├── main.py
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
│   ├── static
│   │   └── shared
│   │       ├── script.js
│   │       └── style.css
│   ├── templates
│   │   └── base.html
│   ├── test_push_notification.py
│   ├── test_push_notification_e2e.py
│   └── tests
│       ├── __init__.py
│       ├── conftest.py
│       ├── postchain
│       │   ├── __init__.py
│       │   ├── models_test.py
│       │   ├── random_gen_prompts.md
│       │   ├── test_cases.json
│       │   ├── test_langchain_workflow.py
│       │   ├── test_providers.py
│       │   ├── test_providers_abstracted.py
│       │   ├── test_simple_multimodel_stream.py
│       │   ├── test_structured_output.py
│       │   └── test_utils.py
│       ├── test_main.py
│       ├── test_sui_service.py
│       ├── test_user_thread_endpoints.py
│       └── tools
│           ├── __init__.py
│           ├── direct_search_diagnostic.py
│           ├── direct_search_test.py
│           ├── test_brave_search.py
│           ├── test_calculator.py
│           ├── test_multimodel_with_tools.py
│           ├── test_recent_events.py
│           ├── test_search_tools_report.py
│           ├── test_tavily_search.py
│           └── test_updated_search.py
├── choir_coin
│   └── choir_coin
│       ├── Move.lock
│       ├── Move.toml
│       ├── build
│       │   ├── choir
│       │   │   ├── BuildInfo.yaml
│       │   │   ├── bytecode_modules
│       │   │   │   └── choir.mv
│       │   │   ├── debug_info
│       │   │   │   ├── choir.json
│       │   │   │   └── choir.mvd
│       │   │   └── sources
│       │   │       └── choir.move
│       │   └── locks
│       ├── sources
│       │   └── choir_coin.move
│       └── tests
│           └── choir_coin_tests.move
├── docker-compose.yml
├── docs
│   ├── CHANGELOG.md
│   ├── ChoirPushNotificationsImplementationGuide.md
│   ├── blockchain_integration.md
│   ├── contract_deployment.md
│   ├── core_core.md
│   ├── core_economics.md
│   ├── data_engine_model.md
│   ├── e_business.md
│   ├── e_concept.md
│   ├── evolution_naming.md
│   ├── evolution_token.md
│   ├── issues
│   │   └── retry.md
│   ├── levels
│   │   ├── all.txt
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   └── level5.md
│   ├── mainnet_migration.md
│   ├── notification_system.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_choir_materialization.md
│   ├── postchain_service_redesign.md
│   ├── postchain_temporal_logic.md
│   ├── postchain_ui_redesign.md
│   ├── process_doctrine.md
│   ├── publish_thread_feature.md
│   ├── refactoring_planning_strategy.md
│   ├── relationship_staking.md
│   ├── require_action_phase.md
│   ├── require_experience_phase.md
│   ├── require_intention_phase.md
│   ├── require_observation_phase.md
│   ├── require_phase_requirements_index.md
│   ├── require_understanding_phase.md
│   ├── require_yield_phase.md
│   ├── reward_function.md
│   ├── rewards_system.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   ├── security_considerations.md
│   ├── stack_argument.md
│   ├── state_management_patterns.md
│   ├── tree.md
│   └── wallet_languification.md
├── notebooks
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── render.yaml
├── reward_function.py
├── reward_function_simplified.py
└── scripts
    ├── generate_provider_reports.sh
    ├── generate_quick_search_report.sh
    ├── generate_search_report.sh
    ├── generate_single_provider_report.sh
    ├── sources_displaying.sh
    ├── test_api.sh
    ├── test_notifications.py
    ├── test_postchain_multiturn.sh
    └── test_simulator_notifications.sh

73 directories, 240 files

=== File: docs/CHANGELOG.md ===



==
CHANGELOG.md
==


# Changelog
## [2025-04-28] - 2025-04-28

### Added

- **Mainnet Deployment:** Successfully deployed Choir to the Sui mainnet with package ID `0x4f83f1cd85aefd0254e5b6f93bd344f49dd434269af698998dd5f4baec612898::choir::CHOIR`.
- **Multiple Wallet Support:** Implemented support for multiple wallet accounts with horizontal scrolling in the Wallets tab.
- **Wallet & Thread Import/Export:** Added secure import and export functionality for wallets and threads with biometric protection.
- **Rewards System:** Implemented the full rewards system with:
  - **Novelty Rewards:** Users earn rewards for original content based on vector similarity scores.
  - **Citation Rewards:** Authors of cited content receive rewards when their contributions inform responses.
  - **Choir Coin Integration:** Connected to Sui blockchain for minting and distributing CHOIR tokens.
- **Improved Pagination:** Enhanced pagination system that preserves formatting across pages while maximizing content density.
- **Transaction Management:** Added a dedicated Transactions tab showing a chronological history of all transactions across wallets.
- **Citation Display:** Implemented early UI for displaying and interacting with citations in vector content.
- **Performance Optimization:** Improved app launch and navigation performance by loading only thread metadata initially and loading full content when needed.
- **Model Updates:** Added support for newer AI models and improved model configuration management.

### Changed

- **UI Redesign:** Completely redesigned interface with improved navigation flow and visual consistency.
- **Thread Management:** Enhanced thread persistence with wallet-specific thread storage and optimized loading.
- **Authentication Flow:** Improved authentication with biometric support (FaceID/TouchID) and passcode fallback.

## [2025-04-09] - 2025-04-09

### Added

- **iOS Client Persistence:** Implemented local JSON file storage for thread data.
- **Automatic Thread Titles:** Threads now get an auto-generated title based on the first 10 words of the initial AI Action phase response.
- **Close the Loop UI:** When the yield phase finishes downloading, if the user is viewing the action phase, the UI now automatically transitions to display the final response with a smooth wrap-around animation.


## [2025-03-28] - 2025-03-28

### Added

-   **PostChain Sequential Model Execution:** Implemented a prototype version of the PostChain running on a mobile device, successfully executing a sequence of 6 distinct AI models. This demonstrates the feasibility of the multi-phase workflow and shows initial promise for value generation.

### Changed

-   **Architectural Validation:** The sequential model execution validates the core concept of the PostChain flow. Next steps involve implementing background looping, Qdrant database integration for state persistence and memory, and connecting to the Sui service for reward distribution. These are considered tractable integration tasks.

## [2025-03-27] - 2025-03-27

### Changed

-   **Architectural Focus Shift: Qdrant-Sui MVP Prioritized**
    -   Refocused development efforts on a Minimum Viable Product (MVP) centered around **Qdrant** (data/vector store) and **Sui** (blockchain token/rewards).
    *   Adopted a streamlined architecture using the existing **Python API (FastAPI)** as the central orchestrator.
    *   Leveraging the current **LCEL-based PostChain workflow** (`langchain_workflow.py`) for MVP implementation speed.
    *   Defined clear data structures and interactions between the API, PostChain phases, Qdrant collections (`choir`, `users`, `chat_threads`, `intention_memory`, `observation_memory`), and the `sui_service.py`.
    *   Refined core documentation (`core_core.md`, `state_management_patterns.md`, `blockchain_integration.md`, `security_considerations.md`, `stack_argument.md`, `index.md`) to reflect the MVP scope and architecture.

### Deferred (Post-MVP)

-   Implementation of the full Model Context Protocol (MCP) server architecture.
-   Integration of client-side libSQL caching for offline support.
-   Deployment using Phala Network TEEs for confidential computing.
-   Implementation of the full dynamic economic model (MVP uses basic rewards).

## [Unreleased] - 2025-03-12

### Changed

-   **Major Architectural Pivot: Shifted from LangGraph to MCP Architecture**
    -   Transitioned to Model Context Protocol (MCP) architecture for the Choir platform.
    -   Adopted a service-oriented architecture with each PostChain phase implemented as a separate MCP server.
    -   Implemented MCP Resources for efficient conversation state management and context sharing.
    -   Leveraged MCP Notifications for real-time updates and communication between Host and Servers.
    -   Replaced LangGraph-based workflow orchestration with a Host-application-centric orchestration model using asynchronous tasks.
    -   Refined the focus on modularity, scalability, and security through the MCP architecture.

### Added

-   **Coherent Technology Stack for MCP Architecture:**
    -   **Model Context Protocol (MCP) Architecture:** Service-oriented architecture for PostChain phases, enabling modularity and scalability.
    -   **PySUI:** Maintained PySUI for blockchain integration and economic actions.
    -   **Pydantic:** Continued use of Pydantic for type safety and message validation in the MCP architecture.
    -   **FastAPI/Uvicorn:** Continued use of FastAPI/Uvicorn for the Python API layer, now orchestrating MCP server interactions.
    -   **Docker:** Maintained Docker for containerization and deployment of MCP servers.
    -   **Phala Network:** Maintained Phala Network for TEE-secured operations and confidential computing for MCP servers.

-   **Enhanced Token Economy and Reward System (RL-Driven CHOIR):**
    -   **CHOIR Coins as Training Signals for AI:** Evolved the CHOIR coin to act as training signals for AI models, driving a self-improving AI ecosystem.
    -   **Novelty and Citation Rewards:** Implemented novelty rewards for original prompts and citation rewards for salient contributions, algorithmically distributed by AI models.
    -   **Contract as Data Marketplace Foundation:** Defined the contract as the basis for a data marketplace within Choir, enabling CHOIR-based data access and contribution pricing.
    -   **Data Economy Vision:** Developed the vision for a comprehensive data marketplace where CHOIR serves as the currency for accessing and contributing to valuable datasets.

### Removed

-   Deprecated LangGraph dependency and graph-based state management due to scalability and maintenance concerns.

## [2025-02-25] - 2025-02-25

### Added

-   Implemented UI carousel to improve user experience
-   Added display of priors in the Experience step
-   Resumed active development after coding hiatus

### Planned

-   API streaming implementation to enhance responsiveness
-   Model reconfiguration for improved performance
-   Go multimodel, then multimodal
-   OpenRouter integration
-   Conceptual evolution from "Chorus Cycle" to "Post Chain"
    -   Representing shift from harmonic oscillator (cycle) to anharmonic oscillator (chain)
    -   Aligning interface terminology with underlying model
-   Client-side editable system prompts for customization
-   Additional phases in the Post Chain:
    -   Web search phase for real-time information access
    -   Sandboxed arbitrary tool use phase for enhanced capabilities

## [2025-02-24] - 2025-02-24

### Changed

-   Implemented fractional quantum anharmonic oscillator model for dynamic stake pricing
-   Added fractional parameter α to capture memory effects and non-local interactions
-   Revised parameter modulation formulas for K₀, α, and m to reflect interdependencies
-   Created simulation framework for parameter optimization

## [2025-02-23] - 2025-02-23

### Changed

-   Documented quantum anharmonic oscillator model implementation and dynamic stake pricing mechanism via an effective anharmonic coefficient modulated by approval/refusal statistics.

## [Unreleased]

### Changed

-   Updated all documentation to version 6.0
    -   Transformed structured documentation into fluid prose
    -   Relaxed event-driven architecture requirements for initial TestFlight
    -   Clarified implementation priorities and post-funding features
    -   Maintained theoretical frameworks while focusing on core functionality

### Added

-   Initial Chorus cycle working in iOS simulator
    -   Basic message flow through phases
    -   Response handling
    -   State management

### Documented

-   Created 15 comprehensive issues covering:
    -   Core message system implementation
    -   Type reconciliation with Qdrant
    -   API client updates
    -   Coordinator message flow
    -   User identity management
    -   Thread state management
    -   Integration testing
    -   Error handling strategy
    -   Performance monitoring
    -   State recovery
    -   Thread sheet implementation
    -   Thread contract implementation
    -   Message rewards system
    -   LanceDB migration
    -   Citation visualization

### Architecture

-   Defined clear type system for messages
-   Planned migration to LanceDB
-   Structured multimodal support strategy

### Technical Debt

-   Identified areas needing more specification:
    -   Thread Sheet UI (marked as "AI SLOP")
    -   Reward formulas need verification
    -   Migration pipeline needs careful implementation

## [0.4.2] - 2024-11-09

### Added

-   Development principles with focus on groundedness
-   Basic chat interface implementation
-   SwiftData message persistence // this subsequently became a problem. swiftdata is coupled with swiftui and there was interference between view rendering and data persistence
-   Initial Action step foundation

### Changed

-   Shifted to iterative, ground-up development approach
-   Simplified initial implementation scope
-   Focused on working software over theoretical architecture
-   Adopted step-by-step Chorus Cycle implementation strategy

### Principles

-   Established groundedness as core development principle
-   Emphasized iterative growth and natural evolution
-   Prioritized practical progress over theoretical completeness
-   Introduced flexible, evidence-based development flow

## [0.4.1] - 2024-11-08

### Added

-   Self-creation process
-   Post-training concepts
-   Concurrent processing ideas
-   Democratic framing
-   Thoughtspace visualization

### Changed

-   Renamed Update to Understanding
-   Enhanced step descriptions
-   Refined documentation focus
-   Improved pattern recognition

## [0.4.0] - 2024-10-30

### Added

-   Swift architecture plans
-   Frontend-driven design
-   Service layer concepts
-   Chorus cycle definition

### Changed

-   Enhanced system architecture
-   Refined core patterns

## [0.3.5] - 2024-09-01

-   Choir.chat as a web3 dapp
-   messed around with solana
-   used a lot of time messing with next.js/react/typescript/javascript
-   recognized that browser extension wallet is terrible ux

## [0.3.0] - 2024-03-01

### Added

-   ChoirGPT development from winter 2023 to spring 2024

-   First developed as a ChatGPT plugin, then a Custom GPT
-   The first global RAG system / collective intelligence as a GPT

## [0.2.10] - 2023-04-01

### Added

-   Ahpta development from winter 2022 to spring 2023

## [0.2.9] - 2022-04-01

### Added

-   V10 development from fall 2021 to winter 2022

## [0.2.8] - 2021-04-01

### Added

-   Elevisio development from spring 2020 to spring 2021

## [0.2.7] - 2020-04-01

### Added

-   Bluem development from spring 2019 to spring 2020

## [0.2.6] - 2019-04-01

### Added

-   Blocstar development from fall 2018 to spring 2019

## [0.2.5] - 2018-04-01

### Added

-   Phase4word development from summer 2017 to spring 2018

### Changed

-   Showed Phase4word to ~50 people in spring 2018, received critical feedback
-   Codebase remains in 2018 vintage

## [0.2.0] - 2016-06-20

### Added

-   Phase4 party concept
-   Early democracy technology
-   Initial value systems

### Changed

-   Moved beyond truth measurement framing
-   Refined core concepts

## [0.1.0] - 2015-07-15

### Added

-   Initial simulation hypothesis insight
-   "Kandor"
-   Quantum information concepts
-   Planetary coherence vision
-   Core system ideas

=== File: docs/scripts/combiner.sh ===



==
combiner.sh
==


#!/bin/bash

# Revised prefix arrays
level0_prefixes=("")  # Basic technical integration
level1_prefixes=("core" "requirements")  # Core system components
level2_prefixes=("e")           # Business/concept/implementation
level3_prefixes=("plan")               # Plans
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
