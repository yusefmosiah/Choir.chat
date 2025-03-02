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
│       ├── Components
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
│   │   ├── langchain_utils.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── postchain
│   │   │   ├── __init__.py
│   │   │   ├── provider_info.md
│   │   │   └── schemas
│   │   │       ├── __init__.py
│   │   │       ├── aeiou.py
│   │   │       └── state.py
│   │   ├── routers
│   │   │   ├── balance.py
│   │   │   ├── chorus.py
│   │   │   ├── embeddings.py
│   │   │   ├── postchain.py
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
│       ├── postchain
│       │   ├── __init__.py
│       │   ├── run_all_tests.py
│       │   ├── test_langgraph_multiturn.py
│       │   ├── test_langgraph_multiturn_abstracted.py
│       │   ├── test_providers.py
│       │   ├── test_providers_abstracted.py
│       │   ├── test_simple_multimodel.py
│       │   ├── test_structured_output.py
│       │   └── test_structured_output_abstracted.py
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
│   ├── fqaho_simulation.md
│   ├── fqaho_visualization.md
│   ├── levels
│   │   ├── all.txt
│   │   ├── level-1.md
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   └── level5.md
│   ├── plan_anonymity_by_default.md
│   ├── plan_identity_as_a_service.md
│   ├── plan_langgraph.md
│   ├── plan_langgraph_postchain.md
│   ├── plan_libsql.md
│   ├── plan_spec_postchain.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   └── tree.md
├── notebooks
│   ├── fqaho_simulation.ipynb
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── render.yaml
└── ~

55 directories, 135 files
