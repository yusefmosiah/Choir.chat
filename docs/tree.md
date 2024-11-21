# Choir Directory Structure
## Output of $ tree -I 'venv|archive|__pycache__|iOS_Example' | pbcopy

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
│       ├── ChorusResponse.swift
│       ├── MessageRow.swift
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
│   │   │   ├── vectors.py
│   │   │   └── wallet.py
│   │   ├── services
│   │   │   ├── __init__.py
│   │   │   ├── chorus.py
│   │   │   ├── sui_service.py
│   │   │   └── wallet_manager.py
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
│       │   ├── choir
│       │   │   ├── BuildInfo.yaml
│       │   │   ├── bytecode_modules
│       │   │   │   ├── choir.mv
│       │   │   │   └── dependencies
│       │   │   │       ├── MoveStdlib
│       │   │   │       │   ├── address.mv
│       │   │   │       │   ├── ascii.mv
│       │   │   │       │   ├── bcs.mv
│       │   │   │       │   ├── bit_vector.mv
│       │   │   │       │   ├── debug.mv
│       │   │   │       │   ├── fixed_point32.mv
│       │   │   │       │   ├── hash.mv
│       │   │   │       │   ├── macros.mv
│       │   │   │       │   ├── option.mv
│       │   │   │       │   ├── string.mv
│       │   │   │       │   ├── type_name.mv
│       │   │   │       │   ├── u128.mv
│       │   │   │       │   ├── u16.mv
│       │   │   │       │   ├── u256.mv
│       │   │   │       │   ├── u32.mv
│       │   │   │       │   ├── u64.mv
│       │   │   │       │   ├── u8.mv
│       │   │   │       │   ├── uq32_32.mv
│       │   │   │       │   └── vector.mv
│       │   │   │       └── Sui
│       │   │   │           ├── address.mv
│       │   │   │           ├── authenticator_state.mv
│       │   │   │           ├── bag.mv
│       │   │   │           ├── balance.mv
│       │   │   │           ├── bcs.mv
│       │   │   │           ├── bls12381.mv
│       │   │   │           ├── borrow.mv
│       │   │   │           ├── clock.mv
│       │   │   │           ├── coin.mv
│       │   │   │           ├── config.mv
│       │   │   │           ├── deny_list.mv
│       │   │   │           ├── display.mv
│       │   │   │           ├── dynamic_field.mv
│       │   │   │           ├── dynamic_object_field.mv
│       │   │   │           ├── ecdsa_k1.mv
│       │   │   │           ├── ecdsa_r1.mv
│       │   │   │           ├── ecvrf.mv
│       │   │   │           ├── ed25519.mv
│       │   │   │           ├── event.mv
│       │   │   │           ├── groth16.mv
│       │   │   │           ├── group_ops.mv
│       │   │   │           ├── hash.mv
│       │   │   │           ├── hex.mv
│       │   │   │           ├── hmac.mv
│       │   │   │           ├── kiosk.mv
│       │   │   │           ├── kiosk_extension.mv
│       │   │   │           ├── linked_table.mv
│       │   │   │           ├── math.mv
│       │   │   │           ├── object.mv
│       │   │   │           ├── object_bag.mv
│       │   │   │           ├── object_table.mv
│       │   │   │           ├── package.mv
│       │   │   │           ├── pay.mv
│       │   │   │           ├── poseidon.mv
│       │   │   │           ├── priority_queue.mv
│       │   │   │           ├── prover.mv
│       │   │   │           ├── random.mv
│       │   │   │           ├── sui.mv
│       │   │   │           ├── table.mv
│       │   │   │           ├── table_vec.mv
│       │   │   │           ├── token.mv
│       │   │   │           ├── transfer.mv
│       │   │   │           ├── transfer_policy.mv
│       │   │   │           ├── tx_context.mv
│       │   │   │           ├── types.mv
│       │   │   │           ├── url.mv
│       │   │   │           ├── vdf.mv
│       │   │   │           ├── vec_map.mv
│       │   │   │           ├── vec_set.mv
│       │   │   │           ├── versioned.mv
│       │   │   │           ├── zklogin_verified_id.mv
│       │   │   │           └── zklogin_verified_issuer.mv
│       │   │   ├── source_maps
│       │   │   │   ├── choir.json
│       │   │   │   ├── choir.mvsm
│       │   │   │   └── dependencies
│       │   │   │       ├── MoveStdlib
│       │   │   │       │   ├── address.json
│       │   │   │       │   ├── address.mvsm
│       │   │   │       │   ├── ascii.json
│       │   │   │       │   ├── ascii.mvsm
│       │   │   │       │   ├── bcs.json
│       │   │   │       │   ├── bcs.mvsm
│       │   │   │       │   ├── bit_vector.json
│       │   │   │       │   ├── bit_vector.mvsm
│       │   │   │       │   ├── debug.json
│       │   │   │       │   ├── debug.mvsm
│       │   │   │       │   ├── fixed_point32.json
│       │   │   │       │   ├── fixed_point32.mvsm
│       │   │   │       │   ├── hash.json
│       │   │   │       │   ├── hash.mvsm
│       │   │   │       │   ├── macros.json
│       │   │   │       │   ├── macros.mvsm
│       │   │   │       │   ├── option.json
│       │   │   │       │   ├── option.mvsm
│       │   │   │       │   ├── string.json
│       │   │   │       │   ├── string.mvsm
│       │   │   │       │   ├── type_name.json
│       │   │   │       │   ├── type_name.mvsm
│       │   │   │       │   ├── u128.json
│       │   │   │       │   ├── u128.mvsm
│       │   │   │       │   ├── u16.json
│       │   │   │       │   ├── u16.mvsm
│       │   │   │       │   ├── u256.json
│       │   │   │       │   ├── u256.mvsm
│       │   │   │       │   ├── u32.json
│       │   │   │       │   ├── u32.mvsm
│       │   │   │       │   ├── u64.json
│       │   │   │       │   ├── u64.mvsm
│       │   │   │       │   ├── u8.json
│       │   │   │       │   ├── u8.mvsm
│       │   │   │       │   ├── uq32_32.json
│       │   │   │       │   ├── uq32_32.mvsm
│       │   │   │       │   ├── vector.json
│       │   │   │       │   └── vector.mvsm
│       │   │   │       └── Sui
│       │   │   │           ├── address.json
│       │   │   │           ├── address.mvsm
│       │   │   │           ├── authenticator_state.json
│       │   │   │           ├── authenticator_state.mvsm
│       │   │   │           ├── bag.json
│       │   │   │           ├── bag.mvsm
│       │   │   │           ├── balance.json
│       │   │   │           ├── balance.mvsm
│       │   │   │           ├── bcs.json
│       │   │   │           ├── bcs.mvsm
│       │   │   │           ├── bls12381.json
│       │   │   │           ├── bls12381.mvsm
│       │   │   │           ├── borrow.json
│       │   │   │           ├── borrow.mvsm
│       │   │   │           ├── clock.json
│       │   │   │           ├── clock.mvsm
│       │   │   │           ├── coin.json
│       │   │   │           ├── coin.mvsm
│       │   │   │           ├── config.json
│       │   │   │           ├── config.mvsm
│       │   │   │           ├── deny_list.json
│       │   │   │           ├── deny_list.mvsm
│       │   │   │           ├── display.json
│       │   │   │           ├── display.mvsm
│       │   │   │           ├── dynamic_field.json
│       │   │   │           ├── dynamic_field.mvsm
│       │   │   │           ├── dynamic_object_field.json
│       │   │   │           ├── dynamic_object_field.mvsm
│       │   │   │           ├── ecdsa_k1.json
│       │   │   │           ├── ecdsa_k1.mvsm
│       │   │   │           ├── ecdsa_r1.json
│       │   │   │           ├── ecdsa_r1.mvsm
│       │   │   │           ├── ecvrf.json
│       │   │   │           ├── ecvrf.mvsm
│       │   │   │           ├── ed25519.json
│       │   │   │           ├── ed25519.mvsm
│       │   │   │           ├── event.json
│       │   │   │           ├── event.mvsm
│       │   │   │           ├── groth16.json
│       │   │   │           ├── groth16.mvsm
│       │   │   │           ├── group_ops.json
│       │   │   │           ├── group_ops.mvsm
│       │   │   │           ├── hash.json
│       │   │   │           ├── hash.mvsm
│       │   │   │           ├── hex.json
│       │   │   │           ├── hex.mvsm
│       │   │   │           ├── hmac.json
│       │   │   │           ├── hmac.mvsm
│       │   │   │           ├── kiosk.json
│       │   │   │           ├── kiosk.mvsm
│       │   │   │           ├── kiosk_extension.json
│       │   │   │           ├── kiosk_extension.mvsm
│       │   │   │           ├── linked_table.json
│       │   │   │           ├── linked_table.mvsm
│       │   │   │           ├── math.json
│       │   │   │           ├── math.mvsm
│       │   │   │           ├── object.json
│       │   │   │           ├── object.mvsm
│       │   │   │           ├── object_bag.json
│       │   │   │           ├── object_bag.mvsm
│       │   │   │           ├── object_table.json
│       │   │   │           ├── object_table.mvsm
│       │   │   │           ├── package.json
│       │   │   │           ├── package.mvsm
│       │   │   │           ├── pay.json
│       │   │   │           ├── pay.mvsm
│       │   │   │           ├── poseidon.json
│       │   │   │           ├── poseidon.mvsm
│       │   │   │           ├── priority_queue.json
│       │   │   │           ├── priority_queue.mvsm
│       │   │   │           ├── prover.json
│       │   │   │           ├── prover.mvsm
│       │   │   │           ├── random.json
│       │   │   │           ├── random.mvsm
│       │   │   │           ├── sui.json
│       │   │   │           ├── sui.mvsm
│       │   │   │           ├── table.json
│       │   │   │           ├── table.mvsm
│       │   │   │           ├── table_vec.json
│       │   │   │           ├── table_vec.mvsm
│       │   │   │           ├── token.json
│       │   │   │           ├── token.mvsm
│       │   │   │           ├── transfer.json
│       │   │   │           ├── transfer.mvsm
│       │   │   │           ├── transfer_policy.json
│       │   │   │           ├── transfer_policy.mvsm
│       │   │   │           ├── tx_context.json
│       │   │   │           ├── tx_context.mvsm
│       │   │   │           ├── types.json
│       │   │   │           ├── types.mvsm
│       │   │   │           ├── url.json
│       │   │   │           ├── url.mvsm
│       │   │   │           ├── vdf.json
│       │   │   │           ├── vdf.mvsm
│       │   │   │           ├── vec_map.json
│       │   │   │           ├── vec_map.mvsm
│       │   │   │           ├── vec_set.json
│       │   │   │           ├── vec_set.mvsm
│       │   │   │           ├── versioned.json
│       │   │   │           ├── versioned.mvsm
│       │   │   │           ├── zklogin_verified_id.json
│       │   │   │           ├── zklogin_verified_id.mvsm
│       │   │   │           ├── zklogin_verified_issuer.json
│       │   │   │           └── zklogin_verified_issuer.mvsm
│       │   │   └── sources
│       │   │       ├── choir.move
│       │   │       └── dependencies
│       │   │           ├── MoveStdlib
│       │   │           │   ├── address.move
│       │   │           │   ├── ascii.move
│       │   │           │   ├── bcs.move
│       │   │           │   ├── bit_vector.move
│       │   │           │   ├── debug.move
│       │   │           │   ├── fixed_point32.move
│       │   │           │   ├── hash.move
│       │   │           │   ├── macros.move
│       │   │           │   ├── option.move
│       │   │           │   ├── string.move
│       │   │           │   ├── type_name.move
│       │   │           │   ├── u128.move
│       │   │           │   ├── u16.move
│       │   │           │   ├── u256.move
│       │   │           │   ├── u32.move
│       │   │           │   ├── u64.move
│       │   │           │   ├── u8.move
│       │   │           │   ├── uq32_32.move
│       │   │           │   └── vector.move
│       │   │           └── Sui
│       │   │               ├── address.move
│       │   │               ├── authenticator_state.move
│       │   │               ├── bag.move
│       │   │               ├── balance.move
│       │   │               ├── bcs.move
│       │   │               ├── bls12381.move
│       │   │               ├── borrow.move
│       │   │               ├── clock.move
│       │   │               ├── coin.move
│       │   │               ├── config.move
│       │   │               ├── deny_list.move
│       │   │               ├── display.move
│       │   │               ├── dynamic_field.move
│       │   │               ├── dynamic_object_field.move
│       │   │               ├── ecdsa_k1.move
│       │   │               ├── ecdsa_r1.move
│       │   │               ├── ecvrf.move
│       │   │               ├── ed25519.move
│       │   │               ├── event.move
│       │   │               ├── groth16.move
│       │   │               ├── group_ops.move
│       │   │               ├── hash.move
│       │   │               ├── hex.move
│       │   │               ├── hmac.move
│       │   │               ├── kiosk.move
│       │   │               ├── kiosk_extension.move
│       │   │               ├── linked_table.move
│       │   │               ├── math.move
│       │   │               ├── object.move
│       │   │               ├── object_bag.move
│       │   │               ├── object_table.move
│       │   │               ├── package.move
│       │   │               ├── pay.move
│       │   │               ├── poseidon.move
│       │   │               ├── priority_queue.move
│       │   │               ├── prover.move
│       │   │               ├── random.move
│       │   │               ├── sui.move
│       │   │               ├── table.move
│       │   │               ├── table_vec.move
│       │   │               ├── token.move
│       │   │               ├── transfer.move
│       │   │               ├── transfer_policy.move
│       │   │               ├── tx_context.move
│       │   │               ├── types.move
│       │   │               ├── url.move
│       │   │               ├── vdf.move
│       │   │               ├── vec_map.move
│       │   │               ├── vec_set.move
│       │   │               ├── versioned.move
│       │   │               ├── zklogin_verified_id.move
│       │   │               └── zklogin_verified_issuer.move
│       │   └── locks
│       ├── sources
│       │   └── choir_coin.move
│       └── tests
│           └── choir_coin_tests.move
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
    │   ├── issue_0.md
    │   ├── issue_1.md
    │   ├── issue_10.md
    │   ├── issue_11.md
    │   ├── issue_12.md
    │   ├── issue_13.md
    │   ├── issue_2.md
    │   ├── issue_5.md
    │   ├── issue_7.md
    │   ├── issue_8.md
    │   └── issue_9.md
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
    ├── plan_chuser_chthread_chmessage.md
    ├── plan_client_architecture.md
    ├── plan_id_persistence.md
    ├── plan_post-training.md
    ├── plan_proxy_authentication.md
    ├── plan_proxy_security_model.md
    ├── plan_save_users_and_threads.md
    ├── plan_sui_blockchain_integration.md
    ├── plan_swiftdata_required_changes.md
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

56 directories, 436 files
