# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example|dependencies' | pbcopy

.
├── CLAUDE.md
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
│   │   ├── ChoirAPIClient.swift
│   │   └── RESTPostchainAPIClient.swift
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
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── ExperienceSourcesView.swift
│       ├── MessageRow.swift
│       ├── ModelConfigView.swift
│       ├── PaginatedTextView.swift
│       ├── PhaseCard.swift
│       ├── PostchainView.swift
│       ├── PriorCard.swift
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
│   ├── ChoirIntegrationTests.swift
│   ├── ChoirTests.swift
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
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── postchain
│   │   │   ├── README.md
│   │   │   ├── __init__.py
│   │   │   ├── langchain_workflow.py
│   │   │   ├── nodes
│   │   │   ├── postchain_llm.py
│   │   │   ├── prompts
│   │   │   │   └── prompts.py
│   │   │   ├── schemas
│   │   │   │   ├── __init__.py
│   │   │   │   └── state.py
│   │   │   ├── state
│   │   │   └── utils.py
│   │   ├── routers
│   │   │   ├── auth.py
│   │   │   ├── balance.py
│   │   │   ├── postchain.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   └── vectors.py
│   │   ├── services
│   │   │   ├── __init__.py
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
│   ├── main.py
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
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
│       ├── test_database.py
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
│   ├── authentication_flow.md
│   ├── blockchain_integration.md
│   ├── comp_provider_info.md
│   ├── core_core.md
│   ├── core_economics.md
│   ├── core_state_transitions.md
│   ├── data_engine_model.md
│   ├── e_business.md
│   ├── e_concept.md
│   ├── evolution_naming.md
│   ├── evolution_token.md
│   ├── fqaho_simulation.md
│   ├── fqaho_visualization.md
│   ├── levels
│   │   ├── all.txt
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   └── level5.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_chip_materialization.md
│   ├── postchain_temporal_logic.md
│   ├── qdrant_persistence.md
│   ├── require_action_phase.md
│   ├── require_experience_phase.md
│   ├── require_intention_phase.md
│   ├── require_observation_phase.md
│   ├── require_phase_requirements_index.md
│   ├── require_understanding_phase.md
│   ├── require_yield_phase.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   ├── security_considerations.md
│   ├── stack_argument.md
│   ├── state_management_patterns.md
│   └── tree.md
├── notebooks
│   ├── fqaho_simulation.ipynb
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── render.yaml
└── scripts
    ├── generate_provider_reports.sh
    ├── generate_quick_search_report.sh
    ├── generate_search_report.sh
    ├── generate_single_provider_report.sh
    ├── sources_displaying.sh
    └── test_postchain_multiturn.sh

60 directories, 171 files
