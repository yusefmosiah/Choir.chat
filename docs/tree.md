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
│       │       │   ├── choir_tests.mv
│       │       │   └── dependencies
│       │       │       ├── MoveStdlib
│       │       │       │   ├── address.mv
│       │       │       │   ├── ascii.mv
│       │       │       │   ├── ascii_tests.mv
│       │       │       │   ├── bcs.mv
│       │       │       │   ├── bcs_tests.mv
│       │       │       │   ├── bit_vector.mv
│       │       │       │   ├── bit_vector_tests.mv
│       │       │       │   ├── debug.mv
│       │       │       │   ├── fixed_point32.mv
│       │       │       │   ├── fixed_point32_tests.mv
│       │       │       │   ├── hash.mv
│       │       │       │   ├── hash_tests.mv
│       │       │       │   ├── integer_tests.mv
│       │       │       │   ├── macros.mv
│       │       │       │   ├── option.mv
│       │       │       │   ├── option_tests.mv
│       │       │       │   ├── string.mv
│       │       │       │   ├── string_tests.mv
│       │       │       │   ├── type_name.mv
│       │       │       │   ├── type_name_tests.mv
│       │       │       │   ├── u128.mv
│       │       │       │   ├── u128_tests.mv
│       │       │       │   ├── u16.mv
│       │       │       │   ├── u16_tests.mv
│       │       │       │   ├── u256.mv
│       │       │       │   ├── u256_tests.mv
│       │       │       │   ├── u32.mv
│       │       │       │   ├── u32_tests.mv
│       │       │       │   ├── u64.mv
│       │       │       │   ├── u64_tests.mv
│       │       │       │   ├── u8.mv
│       │       │       │   ├── u8_tests.mv
│       │       │       │   ├── unit_test.mv
│       │       │       │   ├── uq32_32.mv
│       │       │       │   ├── uq32_32_tests.mv
│       │       │       │   ├── vector.mv
│       │       │       │   └── vector_tests.mv
│       │       │       └── Sui
│       │       │           ├── address.mv
│       │       │           ├── address_tests.mv
│       │       │           ├── authenticator_state.mv
│       │       │           ├── authenticator_state_tests.mv
│       │       │           ├── bag.mv
│       │       │           ├── bag_tests.mv
│       │       │           ├── balance.mv
│       │       │           ├── bcs.mv
│       │       │           ├── bcs_tests.mv
│       │       │           ├── bls12381.mv
│       │       │           ├── bls12381_tests.mv
│       │       │           ├── borrow.mv
│       │       │           ├── clock.mv
│       │       │           ├── clock_tests.mv
│       │       │           ├── coin.mv
│       │       │           ├── coin_balance_tests.mv
│       │       │           ├── coin_tests.mv
│       │       │           ├── config.mv
│       │       │           ├── config_tests.mv
│       │       │           ├── deny_list.mv
│       │       │           ├── deny_list_tests.mv
│       │       │           ├── display.mv
│       │       │           ├── display_tests.mv
│       │       │           ├── dummy_policy.mv
│       │       │           ├── dynamic_field.mv
│       │       │           ├── dynamic_field_tests.mv
│       │       │           ├── dynamic_object_field.mv
│       │       │           ├── dynamic_object_field_tests.mv
│       │       │           ├── ecdsa_k1.mv
│       │       │           ├── ecdsa_k1_tests.mv
│       │       │           ├── ecdsa_r1.mv
│       │       │           ├── ecdsa_r1_tests.mv
│       │       │           ├── ecvrf.mv
│       │       │           ├── ecvrf_tests.mv
│       │       │           ├── ed25519.mv
│       │       │           ├── ed25519_tests.mv
│       │       │           ├── event.mv
│       │       │           ├── event_tests.mv
│       │       │           ├── fixed_commission.mv
│       │       │           ├── groth16.mv
│       │       │           ├── groth16_tests.mv
│       │       │           ├── group_ops.mv
│       │       │           ├── hash.mv
│       │       │           ├── hash_tests.mv
│       │       │           ├── hex.mv
│       │       │           ├── hex_tests.mv
│       │       │           ├── hmac.mv
│       │       │           ├── hmac_tests.mv
│       │       │           ├── id_tests.mv
│       │       │           ├── item_locked_policy.mv
│       │       │           ├── kiosk.mv
│       │       │           ├── kiosk_borrow_tests.mv
│       │       │           ├── kiosk_extension.mv
│       │       │           ├── kiosk_extensions_tests.mv
│       │       │           ├── kiosk_locked_test.mv
│       │       │           ├── kiosk_marketplace_ext.mv
│       │       │           ├── kiosk_test_utils.mv
│       │       │           ├── kiosk_tests.mv
│       │       │           ├── linked_table.mv
│       │       │           ├── linked_table_tests.mv
│       │       │           ├── malicious_policy.mv
│       │       │           ├── math.mv
│       │       │           ├── math_tests.mv
│       │       │           ├── object.mv
│       │       │           ├── object_bag.mv
│       │       │           ├── object_bag_tests.mv
│       │       │           ├── object_table.mv
│       │       │           ├── object_table_tests.mv
│       │       │           ├── object_tests.mv
│       │       │           ├── package.mv
│       │       │           ├── package_tests.mv
│       │       │           ├── pay.mv
│       │       │           ├── pay_tests.mv
│       │       │           ├── poseidon.mv
│       │       │           ├── poseidon_tests.mv
│       │       │           ├── priority_queue.mv
│       │       │           ├── prover.mv
│       │       │           ├── prover_tests.mv
│       │       │           ├── random.mv
│       │       │           ├── random_tests.mv
│       │       │           ├── royalty_policy.mv
│       │       │           ├── royalty_policy_tests.mv
│       │       │           ├── sui.mv
│       │       │           ├── table.mv
│       │       │           ├── table_tests.mv
│       │       │           ├── table_vec.mv
│       │       │           ├── table_vec_tests.mv
│       │       │           ├── test_random.mv
│       │       │           ├── test_random_tests.mv
│       │       │           ├── test_scenario.mv
│       │       │           ├── test_scenario_tests.mv
│       │       │           ├── test_utils.mv
│       │       │           ├── token.mv
│       │       │           ├── token_actions_tests.mv
│       │       │           ├── token_config_tests.mv
│       │       │           ├── token_public_actions_tests.mv
│       │       │           ├── token_request_tests.mv
│       │       │           ├── token_test_utils.mv
│       │       │           ├── token_treasury_cap_tests.mv
│       │       │           ├── transfer.mv
│       │       │           ├── transfer_policy.mv
│       │       │           ├── transfer_policy_tests.mv
│       │       │           ├── tx_context.mv
│       │       │           ├── tx_context_tests.mv
│       │       │           ├── types.mv
│       │       │           ├── url.mv
│       │       │           ├── url_tests.mv
│       │       │           ├── vdf.mv
│       │       │           ├── vdf_tests.mv
│       │       │           ├── vec_map.mv
│       │       │           ├── vec_map_tests.mv
│       │       │           ├── vec_set.mv
│       │       │           ├── vec_set_tests.mv
│       │       │           ├── verifier_tests.mv
│       │       │           ├── versioned.mv
│       │       │           ├── versioned_tests.mv
│       │       │           ├── witness_policy.mv
│       │       │           ├── witness_policy_tests.mv
│       │       │           ├── zklogin_verified_id.mv
│       │       │           ├── zklogin_verified_id_tests.mv
│       │       │           ├── zklogin_verified_issuer.mv
│       │       │           └── zklogin_verified_issuer_tests.mv
│       │       ├── source_maps
│       │       │   ├── choir.json
│       │       │   ├── choir.mvsm
│       │       │   ├── choir_tests.json
│       │       │   ├── choir_tests.mvsm
│       │       │   └── dependencies
│       │       │       ├── MoveStdlib
│       │       │       │   ├── address.json
│       │       │       │   ├── address.mvsm
│       │       │       │   ├── ascii.json
│       │       │       │   ├── ascii.mvsm
│       │       │       │   ├── ascii_tests.json
│       │       │       │   ├── ascii_tests.mvsm
│       │       │       │   ├── bcs.json
│       │       │       │   ├── bcs.mvsm
│       │       │       │   ├── bcs_tests.json
│       │       │       │   ├── bcs_tests.mvsm
│       │       │       │   ├── bit_vector.json
│       │       │       │   ├── bit_vector.mvsm
│       │       │       │   ├── bit_vector_tests.json
│       │       │       │   ├── bit_vector_tests.mvsm
│       │       │       │   ├── debug.json
│       │       │       │   ├── debug.mvsm
│       │       │       │   ├── fixed_point32.json
│       │       │       │   ├── fixed_point32.mvsm
│       │       │       │   ├── fixed_point32_tests.json
│       │       │       │   ├── fixed_point32_tests.mvsm
│       │       │       │   ├── hash.json
│       │       │       │   ├── hash.mvsm
│       │       │       │   ├── hash_tests.json
│       │       │       │   ├── hash_tests.mvsm
│       │       │       │   ├── integer_tests.json
│       │       │       │   ├── integer_tests.mvsm
│       │       │       │   ├── macros.json
│       │       │       │   ├── macros.mvsm
│       │       │       │   ├── option.json
│       │       │       │   ├── option.mvsm
│       │       │       │   ├── option_tests.json
│       │       │       │   ├── option_tests.mvsm
│       │       │       │   ├── string.json
│       │       │       │   ├── string.mvsm
│       │       │       │   ├── string_tests.json
│       │       │       │   ├── string_tests.mvsm
│       │       │       │   ├── type_name.json
│       │       │       │   ├── type_name.mvsm
│       │       │       │   ├── type_name_tests.json
│       │       │       │   ├── type_name_tests.mvsm
│       │       │       │   ├── u128.json
│       │       │       │   ├── u128.mvsm
│       │       │       │   ├── u128_tests.json
│       │       │       │   ├── u128_tests.mvsm
│       │       │       │   ├── u16.json
│       │       │       │   ├── u16.mvsm
│       │       │       │   ├── u16_tests.json
│       │       │       │   ├── u16_tests.mvsm
│       │       │       │   ├── u256.json
│       │       │       │   ├── u256.mvsm
│       │       │       │   ├── u256_tests.json
│       │       │       │   ├── u256_tests.mvsm
│       │       │       │   ├── u32.json
│       │       │       │   ├── u32.mvsm
│       │       │       │   ├── u32_tests.json
│       │       │       │   ├── u32_tests.mvsm
│       │       │       │   ├── u64.json
│       │       │       │   ├── u64.mvsm
│       │       │       │   ├── u64_tests.json
│       │       │       │   ├── u64_tests.mvsm
│       │       │       │   ├── u8.json
│       │       │       │   ├── u8.mvsm
│       │       │       │   ├── u8_tests.json
│       │       │       │   ├── u8_tests.mvsm
│       │       │       │   ├── unit_test.json
│       │       │       │   ├── unit_test.mvsm
│       │       │       │   ├── uq32_32.json
│       │       │       │   ├── uq32_32.mvsm
│       │       │       │   ├── uq32_32_tests.json
│       │       │       │   ├── uq32_32_tests.mvsm
│       │       │       │   ├── vector.json
│       │       │       │   ├── vector.mvsm
│       │       │       │   ├── vector_tests.json
│       │       │       │   └── vector_tests.mvsm
│       │       │       └── Sui
│       │       │           ├── address.json
│       │       │           ├── address.mvsm
│       │       │           ├── address_tests.json
│       │       │           ├── address_tests.mvsm
│       │       │           ├── authenticator_state.json
│       │       │           ├── authenticator_state.mvsm
│       │       │           ├── authenticator_state_tests.json
│       │       │           ├── authenticator_state_tests.mvsm
│       │       │           ├── bag.json
│       │       │           ├── bag.mvsm
│       │       │           ├── bag_tests.json
│       │       │           ├── bag_tests.mvsm
│       │       │           ├── balance.json
│       │       │           ├── balance.mvsm
│       │       │           ├── bcs.json
│       │       │           ├── bcs.mvsm
│       │       │           ├── bcs_tests.json
│       │       │           ├── bcs_tests.mvsm
│       │       │           ├── bls12381.json
│       │       │           ├── bls12381.mvsm
│       │       │           ├── bls12381_tests.json
│       │       │           ├── bls12381_tests.mvsm
│       │       │           ├── borrow.json
│       │       │           ├── borrow.mvsm
│       │       │           ├── clock.json
│       │       │           ├── clock.mvsm
│       │       │           ├── clock_tests.json
│       │       │           ├── clock_tests.mvsm
│       │       │           ├── coin.json
│       │       │           ├── coin.mvsm
│       │       │           ├── coin_balance_tests.json
│       │       │           ├── coin_balance_tests.mvsm
│       │       │           ├── coin_tests.json
│       │       │           ├── coin_tests.mvsm
│       │       │           ├── config.json
│       │       │           ├── config.mvsm
│       │       │           ├── config_tests.json
│       │       │           ├── config_tests.mvsm
│       │       │           ├── deny_list.json
│       │       │           ├── deny_list.mvsm
│       │       │           ├── deny_list_tests.json
│       │       │           ├── deny_list_tests.mvsm
│       │       │           ├── display.json
│       │       │           ├── display.mvsm
│       │       │           ├── display_tests.json
│       │       │           ├── display_tests.mvsm
│       │       │           ├── dummy_policy.json
│       │       │           ├── dummy_policy.mvsm
│       │       │           ├── dynamic_field.json
│       │       │           ├── dynamic_field.mvsm
│       │       │           ├── dynamic_field_tests.json
│       │       │           ├── dynamic_field_tests.mvsm
│       │       │           ├── dynamic_object_field.json
│       │       │           ├── dynamic_object_field.mvsm
│       │       │           ├── dynamic_object_field_tests.json
│       │       │           ├── dynamic_object_field_tests.mvsm
│       │       │           ├── ecdsa_k1.json
│       │       │           ├── ecdsa_k1.mvsm
│       │       │           ├── ecdsa_k1_tests.json
│       │       │           ├── ecdsa_k1_tests.mvsm
│       │       │           ├── ecdsa_r1.json
│       │       │           ├── ecdsa_r1.mvsm
│       │       │           ├── ecdsa_r1_tests.json
│       │       │           ├── ecdsa_r1_tests.mvsm
│       │       │           ├── ecvrf.json
│       │       │           ├── ecvrf.mvsm
│       │       │           ├── ecvrf_tests.json
│       │       │           ├── ecvrf_tests.mvsm
│       │       │           ├── ed25519.json
│       │       │           ├── ed25519.mvsm
│       │       │           ├── ed25519_tests.json
│       │       │           ├── ed25519_tests.mvsm
│       │       │           ├── event.json
│       │       │           ├── event.mvsm
│       │       │           ├── event_tests.json
│       │       │           ├── event_tests.mvsm
│       │       │           ├── fixed_commission.json
│       │       │           ├── fixed_commission.mvsm
│       │       │           ├── groth16.json
│       │       │           ├── groth16.mvsm
│       │       │           ├── groth16_tests.json
│       │       │           ├── groth16_tests.mvsm
│       │       │           ├── group_ops.json
│       │       │           ├── group_ops.mvsm
│       │       │           ├── hash.json
│       │       │           ├── hash.mvsm
│       │       │           ├── hash_tests.json
│       │       │           ├── hash_tests.mvsm
│       │       │           ├── hex.json
│       │       │           ├── hex.mvsm
│       │       │           ├── hex_tests.json
│       │       │           ├── hex_tests.mvsm
│       │       │           ├── hmac.json
│       │       │           ├── hmac.mvsm
│       │       │           ├── hmac_tests.json
│       │       │           ├── hmac_tests.mvsm
│       │       │           ├── id_tests.json
│       │       │           ├── id_tests.mvsm
│       │       │           ├── item_locked_policy.json
│       │       │           ├── item_locked_policy.mvsm
│       │       │           ├── kiosk.json
│       │       │           ├── kiosk.mvsm
│       │       │           ├── kiosk_borrow_tests.json
│       │       │           ├── kiosk_borrow_tests.mvsm
│       │       │           ├── kiosk_extension.json
│       │       │           ├── kiosk_extension.mvsm
│       │       │           ├── kiosk_extensions_tests.json
│       │       │           ├── kiosk_extensions_tests.mvsm
│       │       │           ├── kiosk_locked_test.json
│       │       │           ├── kiosk_locked_test.mvsm
│       │       │           ├── kiosk_marketplace_ext.json
│       │       │           ├── kiosk_marketplace_ext.mvsm
│       │       │           ├── kiosk_test_utils.json
│       │       │           ├── kiosk_test_utils.mvsm
│       │       │           ├── kiosk_tests.json
│       │       │           ├── kiosk_tests.mvsm
│       │       │           ├── linked_table.json
│       │       │           ├── linked_table.mvsm
│       │       │           ├── linked_table_tests.json
│       │       │           ├── linked_table_tests.mvsm
│       │       │           ├── malicious_policy.json
│       │       │           ├── malicious_policy.mvsm
│       │       │           ├── math.json
│       │       │           ├── math.mvsm
│       │       │           ├── math_tests.json
│       │       │           ├── math_tests.mvsm
│       │       │           ├── object.json
│       │       │           ├── object.mvsm
│       │       │           ├── object_bag.json
│       │       │           ├── object_bag.mvsm
│       │       │           ├── object_bag_tests.json
│       │       │           ├── object_bag_tests.mvsm
│       │       │           ├── object_table.json
│       │       │           ├── object_table.mvsm
│       │       │           ├── object_table_tests.json
│       │       │           ├── object_table_tests.mvsm
│       │       │           ├── object_tests.json
│       │       │           ├── object_tests.mvsm
│       │       │           ├── package.json
│       │       │           ├── package.mvsm
│       │       │           ├── package_tests.json
│       │       │           ├── package_tests.mvsm
│       │       │           ├── pay.json
│       │       │           ├── pay.mvsm
│       │       │           ├── pay_tests.json
│       │       │           ├── pay_tests.mvsm
│       │       │           ├── poseidon.json
│       │       │           ├── poseidon.mvsm
│       │       │           ├── poseidon_tests.json
│       │       │           ├── poseidon_tests.mvsm
│       │       │           ├── priority_queue.json
│       │       │           ├── priority_queue.mvsm
│       │       │           ├── prover.json
│       │       │           ├── prover.mvsm
│       │       │           ├── prover_tests.json
│       │       │           ├── prover_tests.mvsm
│       │       │           ├── random.json
│       │       │           ├── random.mvsm
│       │       │           ├── random_tests.json
│       │       │           ├── random_tests.mvsm
│       │       │           ├── royalty_policy.json
│       │       │           ├── royalty_policy.mvsm
│       │       │           ├── royalty_policy_tests.json
│       │       │           ├── royalty_policy_tests.mvsm
│       │       │           ├── sui.json
│       │       │           ├── sui.mvsm
│       │       │           ├── table.json
│       │       │           ├── table.mvsm
│       │       │           ├── table_tests.json
│       │       │           ├── table_tests.mvsm
│       │       │           ├── table_vec.json
│       │       │           ├── table_vec.mvsm
│       │       │           ├── table_vec_tests.json
│       │       │           ├── table_vec_tests.mvsm
│       │       │           ├── test_random.json
│       │       │           ├── test_random.mvsm
│       │       │           ├── test_random_tests.json
│       │       │           ├── test_random_tests.mvsm
│       │       │           ├── test_scenario.json
│       │       │           ├── test_scenario.mvsm
│       │       │           ├── test_scenario_tests.json
│       │       │           ├── test_scenario_tests.mvsm
│       │       │           ├── test_utils.json
│       │       │           ├── test_utils.mvsm
│       │       │           ├── token.json
│       │       │           ├── token.mvsm
│       │       │           ├── token_actions_tests.json
│       │       │           ├── token_actions_tests.mvsm
│       │       │           ├── token_config_tests.json
│       │       │           ├── token_config_tests.mvsm
│       │       │           ├── token_public_actions_tests.json
│       │       │           ├── token_public_actions_tests.mvsm
│       │       │           ├── token_request_tests.json
│       │       │           ├── token_request_tests.mvsm
│       │       │           ├── token_test_utils.json
│       │       │           ├── token_test_utils.mvsm
│       │       │           ├── token_treasury_cap_tests.json
│       │       │           ├── token_treasury_cap_tests.mvsm
│       │       │           ├── transfer.json
│       │       │           ├── transfer.mvsm
│       │       │           ├── transfer_policy.json
│       │       │           ├── transfer_policy.mvsm
│       │       │           ├── transfer_policy_tests.json
│       │       │           ├── transfer_policy_tests.mvsm
│       │       │           ├── tx_context.json
│       │       │           ├── tx_context.mvsm
│       │       │           ├── tx_context_tests.json
│       │       │           ├── tx_context_tests.mvsm
│       │       │           ├── types.json
│       │       │           ├── types.mvsm
│       │       │           ├── url.json
│       │       │           ├── url.mvsm
│       │       │           ├── url_tests.json
│       │       │           ├── url_tests.mvsm
│       │       │           ├── vdf.json
│       │       │           ├── vdf.mvsm
│       │       │           ├── vdf_tests.json
│       │       │           ├── vdf_tests.mvsm
│       │       │           ├── vec_map.json
│       │       │           ├── vec_map.mvsm
│       │       │           ├── vec_map_tests.json
│       │       │           ├── vec_map_tests.mvsm
│       │       │           ├── vec_set.json
│       │       │           ├── vec_set.mvsm
│       │       │           ├── vec_set_tests.json
│       │       │           ├── vec_set_tests.mvsm
│       │       │           ├── verifier_tests.json
│       │       │           ├── verifier_tests.mvsm
│       │       │           ├── versioned.json
│       │       │           ├── versioned.mvsm
│       │       │           ├── versioned_tests.json
│       │       │           ├── versioned_tests.mvsm
│       │       │           ├── witness_policy.json
│       │       │           ├── witness_policy.mvsm
│       │       │           ├── witness_policy_tests.json
│       │       │           ├── witness_policy_tests.mvsm
│       │       │           ├── zklogin_verified_id.json
│       │       │           ├── zklogin_verified_id.mvsm
│       │       │           ├── zklogin_verified_id_tests.json
│       │       │           ├── zklogin_verified_id_tests.mvsm
│       │       │           ├── zklogin_verified_issuer.json
│       │       │           ├── zklogin_verified_issuer.mvsm
│       │       │           ├── zklogin_verified_issuer_tests.json
│       │       │           └── zklogin_verified_issuer_tests.mvsm
│       │       └── sources
│       │           ├── choir.move
│       │           ├── choir_tests.move
│       │           └── dependencies
│       │               ├── MoveStdlib
│       │               │   ├── address.move
│       │               │   ├── ascii.move
│       │               │   ├── ascii_tests.move
│       │               │   ├── bcs.move
│       │               │   ├── bcs_tests.move
│       │               │   ├── bit_vector.move
│       │               │   ├── bit_vector_tests.move
│       │               │   ├── debug.move
│       │               │   ├── fixed_point32.move
│       │               │   ├── fixed_point32_tests.move
│       │               │   ├── hash.move
│       │               │   ├── hash_tests.move
│       │               │   ├── integer_tests.move
│       │               │   ├── macros.move
│       │               │   ├── option.move
│       │               │   ├── option_tests.move
│       │               │   ├── string.move
│       │               │   ├── string_tests.move
│       │               │   ├── type_name.move
│       │               │   ├── type_name_tests.move
│       │               │   ├── u128.move
│       │               │   ├── u128_tests.move
│       │               │   ├── u16.move
│       │               │   ├── u16_tests.move
│       │               │   ├── u256.move
│       │               │   ├── u256_tests.move
│       │               │   ├── u32.move
│       │               │   ├── u32_tests.move
│       │               │   ├── u64.move
│       │               │   ├── u64_tests.move
│       │               │   ├── u8.move
│       │               │   ├── u8_tests.move
│       │               │   ├── unit_test.move
│       │               │   ├── uq32_32.move
│       │               │   ├── uq32_32_tests.move
│       │               │   ├── vector.move
│       │               │   └── vector_tests.move
│       │               └── Sui
│       │                   ├── address.move
│       │                   ├── address_tests.move
│       │                   ├── authenticator_state.move
│       │                   ├── authenticator_state_tests.move
│       │                   ├── bag.move
│       │                   ├── bag_tests.move
│       │                   ├── balance.move
│       │                   ├── bcs.move
│       │                   ├── bcs_tests.move
│       │                   ├── bls12381.move
│       │                   ├── bls12381_tests.move
│       │                   ├── borrow.move
│       │                   ├── clock.move
│       │                   ├── clock_tests.move
│       │                   ├── coin.move
│       │                   ├── coin_balance_tests.move
│       │                   ├── coin_tests.move
│       │                   ├── config.move
│       │                   ├── config_tests.move
│       │                   ├── deny_list.move
│       │                   ├── deny_list_tests.move
│       │                   ├── display.move
│       │                   ├── display_tests.move
│       │                   ├── dummy_policy.move
│       │                   ├── dynamic_field.move
│       │                   ├── dynamic_field_tests.move
│       │                   ├── dynamic_object_field.move
│       │                   ├── dynamic_object_field_tests.move
│       │                   ├── ecdsa_k1.move
│       │                   ├── ecdsa_k1_tests.move
│       │                   ├── ecdsa_r1.move
│       │                   ├── ecdsa_r1_tests.move
│       │                   ├── ecvrf.move
│       │                   ├── ecvrf_tests.move
│       │                   ├── ed25519.move
│       │                   ├── ed25519_tests.move
│       │                   ├── event.move
│       │                   ├── event_tests.move
│       │                   ├── fixed_commission.move
│       │                   ├── groth16.move
│       │                   ├── groth16_tests.move
│       │                   ├── group_ops.move
│       │                   ├── hash.move
│       │                   ├── hash_tests.move
│       │                   ├── hex.move
│       │                   ├── hex_tests.move
│       │                   ├── hmac.move
│       │                   ├── hmac_tests.move
│       │                   ├── id_tests.move
│       │                   ├── item_locked_policy.move
│       │                   ├── kiosk.move
│       │                   ├── kiosk_borrow_tests.move
│       │                   ├── kiosk_extension.move
│       │                   ├── kiosk_extensions_tests.move
│       │                   ├── kiosk_locked_test.move
│       │                   ├── kiosk_marketplace_ext.move
│       │                   ├── kiosk_test_utils.move
│       │                   ├── kiosk_tests.move
│       │                   ├── linked_table.move
│       │                   ├── linked_table_tests.move
│       │                   ├── malicious_policy.move
│       │                   ├── math.move
│       │                   ├── math_tests.move
│       │                   ├── object.move
│       │                   ├── object_bag.move
│       │                   ├── object_bag_tests.move
│       │                   ├── object_table.move
│       │                   ├── object_table_tests.move
│       │                   ├── object_tests.move
│       │                   ├── package.move
│       │                   ├── package_tests.move
│       │                   ├── pay.move
│       │                   ├── pay_tests.move
│       │                   ├── poseidon.move
│       │                   ├── poseidon_tests.move
│       │                   ├── priority_queue.move
│       │                   ├── prover.move
│       │                   ├── prover_tests.move
│       │                   ├── random.move
│       │                   ├── random_tests.move
│       │                   ├── royalty_policy.move
│       │                   ├── royalty_policy_tests.move
│       │                   ├── sui.move
│       │                   ├── table.move
│       │                   ├── table_tests.move
│       │                   ├── table_vec.move
│       │                   ├── table_vec_tests.move
│       │                   ├── test_random.move
│       │                   ├── test_random_tests.move
│       │                   ├── test_scenario.move
│       │                   ├── test_scenario_tests.move
│       │                   ├── test_utils.move
│       │                   ├── token.move
│       │                   ├── token_actions_tests.move
│       │                   ├── token_config_tests.move
│       │                   ├── token_public_actions_tests.move
│       │                   ├── token_request_tests.move
│       │                   ├── token_test_utils.move
│       │                   ├── token_treasury_cap_tests.move
│       │                   ├── transfer.move
│       │                   ├── transfer_policy.move
│       │                   ├── transfer_policy_tests.move
│       │                   ├── tx_context.move
│       │                   ├── tx_context_tests.move
│       │                   ├── types.move
│       │                   ├── url.move
│       │                   ├── url_tests.move
│       │                   ├── vdf.move
│       │                   ├── vdf_tests.move
│       │                   ├── vec_map.move
│       │                   ├── vec_map_tests.move
│       │                   ├── vec_set.move
│       │                   ├── vec_set_tests.move
│       │                   ├── verifier_tests.move
│       │                   ├── versioned.move
│       │                   ├── versioned_tests.move
│       │                   ├── witness_policy.move
│       │                   ├── witness_policy_tests.move
│       │                   ├── zklogin_verified_id.move
│       │                   ├── zklogin_verified_id_tests.move
│       │                   ├── zklogin_verified_issuer.move
│       │                   └── zklogin_verified_issuer_tests.move
│       ├── sources
│       │   └── choir_coin.move
│       └── tests
│           └── choir_coin_tests.move
├── docker-compose.yml
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
    ├── guide_pysui.md
    ├── guide_render_checklist_updated.md
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

55 directories, 793 files
