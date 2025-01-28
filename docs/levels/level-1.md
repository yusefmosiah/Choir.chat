# Level -1 Documentation



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
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── Choir.entitlements
│   ├── ContentView.swift
│   ├── Coordinators
│   │   ├── MockChorusCoordinator.swift
│   │   └── RESTChorusCoordinator.swift
│   ├── Info.plist
│   ├── Models
│   │   ├── ChoirThread.swift
│   │   ├── ChorusModels.swift
│   │   └── Phase.swift
│   ├── Networking
│   │   └── ChorusAPIClient.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Protocols
│   │   └── ChorusCoordinator.swift
│   ├── Services
│   │   ├── KeychainService.swift
│   │   └── WalletManager.swift
│   ├── ViewModels
│   │   └── ChorusViewModel.swift
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── ChorusCycleView.swift
│       ├── MessageRow.swift
│       ├── Thread
│       │   └── Components
│       │       ├── ThreadInputBar.swift
│       │       └── ThreadMessageList.swift
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
│   └── ChorusAPIClientTests.swift
├── ChoirUITests
│   ├── ChoirUITests.swift
│   └── ChoirUITestsLaunchTests.swift
├── api
│   ├── Dockerfile
│   ├── __init__.py
│   ├── app
│   │   ├── __init__.py
│   │   ├── chorus_cycle.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── routers
│   │   │   ├── balance.py
│   │   │   ├── chorus.py
│   │   │   ├── embeddings.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   └── vectors.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   ├── chorus.py
│   │   │   └── sui_service.py
│   │   └── utils.py
│   ├── main.py
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
│   ├── run_tests.sh
│   └── tests
│       ├── __init__.py
│       ├── conftest.py
│       ├── test_chorus_endpoints.py
│       ├── test_core_endpoints.py
│       ├── test_main.py
│       ├── test_response_schemas.py
│       ├── test_structured_outputs.py
│       ├── test_sui_service.py
│       └── test_user_thread_endpoints.py
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
│   ├── CHANGELOG.md
│   ├── core_core.md
│   ├── core_economics.md
│   ├── core_state_transitions.md
│   ├── data_engine_model.md
│   ├── e_business.md
│   ├── e_concept.md
│   ├── evolution_naming.md
│   ├── evolution_token.md
│   ├── issues
│   │   ├── issue_0.md
│   │   ├── issue_1.md
│   │   ├── issue_10.md
│   │   ├── issue_11.md
│   │   ├── issue_12.md
│   │   ├── issue_13.md
│   │   ├── issue_2.md
│   │   ├── issue_5.md
│   │   ├── issue_7.md
│   │   ├── issue_8.md
│   │   └── issue_9.md
│   ├── levels
│   │   ├── level-1.md
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   ├── level5.md
│   │   └── level_organization.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_identity_as_a_service.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   └── tree.md
└── render.yaml

49 directories, 117 files

=== File: docs/CHANGELOG.md ===



==
CHANGELOG.md
==


# Changelog

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
- Documented quantum harmonic oscillator model implementation

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
