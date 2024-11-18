# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__' | pbcopy

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
│   ├── ViewModels
│   │   └── ChorusViewModel.swift
│   └── Views
│       ├── ChoirThreadDetailView.swift
│       ├── ChorusCycleView.swift
│       ├── ChorusResponse.swift
│       └── MessageRow.swift
├── Choir.xcodeproj
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       └── configuration
│   │   └── xcuserdata
│   │       └── wiz.xcuserdatad
│   │           └── UserInterfaceState.xcuserstate
│   └── xcuserdata
│       └── wiz.xcuserdatad
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
│   │   │   ├── chorus.py
│   │   │   ├── embeddings.py
│   │   │   ├── threads.py
│   │   │   ├── users.py
│   │   │   └── vectors.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   └── chorus.py
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
│       └── test_user_thread_endpoints.py
└── docs
    ├── CHANGELOG.md
    ├── Impl_Security.md
    ├── Meta_Evolution.md
    ├── Model_Foundation_Evolution.md
    ├── Model_Metastability.md
    ├── core_architecture.md
    ├── core_chorus.md
    ├── core_core.md
    ├── core_economics.md
    ├── core_knowledge.md
    ├── core_patterns.md
    ├── core_state.md
    ├── core_state_transitions.md
    ├── data_engine_model.md
    ├── docs_dev_principles.md
    ├── docs_operators.md
    ├── e_business.md
    ├── e_concept.md
    ├── e_questions.md
    ├── e_reference.md
    ├── goal_architecture.md
    ├── goal_evolution.md
    ├── goal_implementation.md
    ├── goal_wed_nov_13_2024.md
    ├── harmonic_intelligence.md
    ├── issues
    │   ├── issue_-1.md
    │   ├── issue_0.md
    │   ├── issue_1.md
    │   ├── issue_10.md
    │   ├── issue_11.md
    │   ├── issue_12.md
    │   ├── issue_13.md
    │   ├── issue_14.md
    │   ├── issue_15.md
    │   ├── issue_2.md
    │   ├── issue_3.md
    │   ├── issue_4.md
    │   ├── issue_5.md
    │   ├── issue_6.md
    │   ├── issue_7.md
    │   ├── issue_8.md
    │   ├── issue_9.md
    │   └── issues_1-10.md
    ├── levels
    │   ├── level-1.md
    │   ├── level0.md
    │   ├── level1.md
    │   ├── level2.md
    │   ├── level3.md
    │   ├── level4.md
    │   ├── level5.md
    │   └── level_organization.md
    ├── plan_carousel_ui_pattern.md
    ├── plan_client_architecture.md
    ├── plan_client_side_processing.md
    ├── plan_id_persistence.md
    ├── plan_post-training.md
    ├── plan_proxy_authentication.md
    ├── plan_proxy_security_model.md
    ├── plan_save_users_and_threads.md
    ├── plan_sui_blockchain_integration.md
    ├── plan_swiftui_chorus_integration.md
    ├── plan_thoughtspace.md
    ├── plan_tokenomics.md
    ├── prompt_chorus_cycle.md
    ├── prompt_getting_started.md
    ├── prompt_reentry.md
    ├── prompt_summary_prompt.md
    ├── prompt_wake_up.md
    ├── reward_model.md
    ├── scripts
    │   ├── combiner.sh
    │   └── update_tree.sh
    ├── self_creation_process.md
    ├── theory_choir_harmonics.md
    ├── theory_dynamics.md
    ├── theory_economics.md
    ├── theory_foundation.md
    ├── theory_harmonic_intelligence.md
    ├── theory_oscillator_cooling.md
    ├── theory_theory.md
    └── tree.md

36 directories, 139 files
