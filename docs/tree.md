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
