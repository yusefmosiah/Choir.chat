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
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── Components
│       ├── MessageRow.swift
│       ├── PostchainView.swift
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
│   │   │   ├── graph.py
│   │   │   ├── postchain_graph.py
│   │   │   ├── provider_info.md
│   │   │   ├── schemas
│   │   │   │   ├── __init__.py
│   │   │   │   └── state.py
│   │   │   ├── simple_graph.py
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
│   ├── main.py
│   ├── postchain_tests.log
│   ├── pyproject.toml
│   ├── pytest.ini
│   ├── requirements.txt
│   ├── run_tests.sh
│   ├── test_reports
│   │   └── groq
│   │       ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_180115.json
│   │       ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_180115.md
│   │       ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_180124.json
│   │       ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_180124.md
│   │       ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_180112.json
│   │       ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_180112.md
│   │       ├── llama_3.3_70b_versatile_super_bowl_search_20250307_180054.json
│   │       ├── llama_3.3_70b_versatile_super_bowl_search_20250307_180054.md
│   │       ├── qwen_qwq_32b_super_bowl_search_20250307_180055.json
│   │       └── qwen_qwq_32b_super_bowl_search_20250307_180055.md
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
│       │   ├── test_state_management.py
│       │   ├── test_stream.py
│       │   ├── test_structured_output.py
│       │   ├── test_tool_multimodel.py
│       │   ├── test_tool_random_multimodel.py
│       │   └── test_utils.py
│       ├── test_main.py
│       ├── test_sui_service.py
│       ├── test_user_thread_endpoints.py
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
│   ├── CHANGELOG.md
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
│   ├── implementation_slices
│   │   ├── plan_lp_iteration_1.md
│   │   ├── plan_lp_iteration_2.md
│   │   ├── plan_lp_iteration_3.md
│   │   ├── plan_lp_iteration_4.md
│   │   ├── plan_lp_iteration_5.md
│   │   ├── plan_lp_iteration_6.md
│   │   ├── plan_lp_iteration_7.md
│   │   └── plan_lp_iteration_8.md
│   ├── levels
│   │   ├── all.txt
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   └── level5.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_identity_as_a_service.md
│   ├── plan_langgraph_postchain.md
│   ├── plan_langgraph_postchain_iteration.md
│   ├── plan_libsql.md
│   ├── plan_model_config_checklist.md
│   ├── plan_postchain_checklist.md
│   ├── plan_postchain_graph_api_checklist.md
│   ├── plan_postchain_migration_checklist.md
│   ├── plan_tools_qdrant_checklist.md
│   ├── plan_tools_search_checklist.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   └── tree.md
├── frontend
├── notebooks
│   ├── fqaho_simulation.ipynb
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── postchain_tests.log
├── render.yaml
├── reports
└── scripts
    ├── generate_provider_reports.sh
    ├── generate_quick_search_report.sh
    ├── generate_search_report.sh
    └── generate_single_provider_report.sh

62 directories, 200 files
