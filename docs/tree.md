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
│   │   ├── Components
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
│   │   │   ├── schemas
│   │   │   │   ├── __init__.py
│   │   │   │   └── state.py
│   │   │   ├── simple_graph.py
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
│   │   ├── stack_argument.md
│   │   ├── state_management_overview.md
│   │   ├── thread_contract_model.md
│   │   └── token_economy_model.md
│   ├── 3-implementation
│   │   ├── actor_debugging_guide.md
│   │   ├── actor_implementation_guide.md
│   │   ├── actor_testing_guide.md
│   │   ├── developer_quickstart.md
│   │   ├── message_protocol_reference.md
│   │   ├── migration_guide_for_developers.md
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
│   ├── architecture_reorganization_checklist.md
│   ├── architecture_reorganization_plan.md
│   ├── architecture_transformation_checklist.md
│   ├── architecture_transition_narrative.md
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
│   ├── migration_langgraph_to_actor.md
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

68 directories, 230 files
