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
│   │   ├── chorus_graph.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── langchain_utils.py
│   │   ├── models
│   │   │   ├── __init__.py
│   │   │   └── api.py
│   │   ├── postchain
│   │   │   ├── __init__.py
│   │   │   ├── api.py
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
│   │   ├── tools
│   │   │   ├── __init__.py
│   │   │   ├── base.py
│   │   │   ├── brave_search.py
│   │   │   ├── calculator.py
│   │   │   ├── conversation.py
│   │   │   ├── duckduckgo_search.py
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
│   │   ├── anthropic
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_160927.json
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_160927.md
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_162901.json
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_162901.md
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_164203.json
│   │   │   ├── claude_3_5_haiku_latest_super_bowl_search_20250307_164203.md
│   │   │   ├── claude_3_7_sonnet_latest_super_bowl_search_20250307_160909.json
│   │   │   ├── claude_3_7_sonnet_latest_super_bowl_search_20250307_160909.md
│   │   │   ├── claude_3_7_sonnet_latest_super_bowl_search_20250307_162851.json
│   │   │   ├── claude_3_7_sonnet_latest_super_bowl_search_20250307_162851.md
│   │   │   ├── claude_3_7_sonnet_latest_super_bowl_search_20250307_164152.json
│   │   │   └── claude_3_7_sonnet_latest_super_bowl_search_20250307_164152.md
│   │   ├── cohere
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_160947.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_160947.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161256.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161256.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161703.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161703.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161905.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_161905.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162145.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162145.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162206.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162206.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162248.json
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_162248.md
│   │   │   ├── command_r7b_12_2024_super_bowl_search_20250307_164047.json
│   │   │   └── command_r7b_12_2024_super_bowl_search_20250307_164047.md
│   │   ├── fireworks
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_164059.json
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_164059.md
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_164655.json
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_164655.md
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_165128.json
│   │   │   ├── deepseek_r1_super_bowl_search_20250307_165128.md
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_164104.json
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_164104.md
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_164700.json
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_164700.md
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_165138.json
│   │   │   ├── deepseek_v3_super_bowl_search_20250307_165138.md
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_164106.json
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_164106.md
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_164708.json
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_164708.md
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_165146.json
│   │   │   ├── qwen2p5_coder_32b_instruct_super_bowl_search_20250307_165146.md
│   │   │   ├── qwen_qwq_32b_super_bowl_search_20250307_164709.json
│   │   │   ├── qwen_qwq_32b_super_bowl_search_20250307_164709.md
│   │   │   ├── qwq_32b_super_bowl_search_20250307_165147.json
│   │   │   └── qwq_32b_super_bowl_search_20250307_165147.md
│   │   ├── google
│   │   │   ├── gemini_2.0_flash_lite_super_bowl_search_20250307_162830.json
│   │   │   ├── gemini_2.0_flash_lite_super_bowl_search_20250307_162830.md
│   │   │   ├── gemini_2.0_flash_lite_super_bowl_search_20250307_163412.json
│   │   │   ├── gemini_2.0_flash_lite_super_bowl_search_20250307_163412.md
│   │   │   ├── gemini_2.0_flash_super_bowl_search_20250307_162822.json
│   │   │   ├── gemini_2.0_flash_super_bowl_search_20250307_162822.md
│   │   │   ├── gemini_2.0_flash_super_bowl_search_20250307_163406.json
│   │   │   ├── gemini_2.0_flash_super_bowl_search_20250307_163406.md
│   │   │   ├── gemini_2.0_flash_thinking_exp_01_21_super_bowl_search_20250307_162835.json
│   │   │   ├── gemini_2.0_flash_thinking_exp_01_21_super_bowl_search_20250307_162835.md
│   │   │   ├── gemini_2.0_flash_thinking_exp_01_21_super_bowl_search_20250307_163417.json
│   │   │   ├── gemini_2.0_flash_thinking_exp_01_21_super_bowl_search_20250307_163417.md
│   │   │   ├── gemini_2.0_pro_exp_02_05_super_bowl_search_20250307_162831.json
│   │   │   ├── gemini_2.0_pro_exp_02_05_super_bowl_search_20250307_162831.md
│   │   │   ├── gemini_2.0_pro_exp_02_05_super_bowl_search_20250307_163413.json
│   │   │   └── gemini_2.0_pro_exp_02_05_super_bowl_search_20250307_163413.md
│   │   ├── groq
│   │   │   ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_164506.json
│   │   │   ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_164506.md
│   │   │   ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_164806.json
│   │   │   ├── deepseek_r1_distill_llama_70b_specdec_super_bowl_search_20250307_164806.md
│   │   │   ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_164506.json
│   │   │   ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_164506.md
│   │   │   ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_164806.json
│   │   │   ├── deepseek_r1_distill_llama_70b_super_bowl_search_20250307_164806.md
│   │   │   ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_164503.json
│   │   │   ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_164503.md
│   │   │   ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_164803.json
│   │   │   ├── deepseek_r1_distill_qwen_32b_super_bowl_search_20250307_164803.md
│   │   │   ├── llama_3.3_70b_versatile_super_bowl_search_20250307_164457.json
│   │   │   ├── llama_3.3_70b_versatile_super_bowl_search_20250307_164457.md
│   │   │   ├── llama_3.3_70b_versatile_super_bowl_search_20250307_164757.json
│   │   │   ├── llama_3.3_70b_versatile_super_bowl_search_20250307_164757.md
│   │   │   ├── qwen_qwq_32b_super_bowl_search_20250307_164457.json
│   │   │   ├── qwen_qwq_32b_super_bowl_search_20250307_164457.md
│   │   │   ├── qwen_qwq_32b_super_bowl_search_20250307_164758.json
│   │   │   └── qwen_qwq_32b_super_bowl_search_20250307_164758.md
│   │   ├── mistral
│   │   │   ├── codestral_latest_super_bowl_search_20250307_164328.json
│   │   │   ├── codestral_latest_super_bowl_search_20250307_164328.md
│   │   │   ├── codestral_latest_super_bowl_search_20250307_164739.json
│   │   │   ├── codestral_latest_super_bowl_search_20250307_164739.md
│   │   │   ├── mistral_large_latest_super_bowl_search_20250307_164323.json
│   │   │   ├── mistral_large_latest_super_bowl_search_20250307_164323.md
│   │   │   ├── mistral_large_latest_super_bowl_search_20250307_164733.json
│   │   │   ├── mistral_large_latest_super_bowl_search_20250307_164733.md
│   │   │   ├── mistral_small_latest_super_bowl_search_20250307_164312.json
│   │   │   ├── mistral_small_latest_super_bowl_search_20250307_164312.md
│   │   │   ├── mistral_small_latest_super_bowl_search_20250307_164726.json
│   │   │   ├── mistral_small_latest_super_bowl_search_20250307_164726.md
│   │   │   ├── pixtral_12b_2409_super_bowl_search_20250307_164306.json
│   │   │   ├── pixtral_12b_2409_super_bowl_search_20250307_164306.md
│   │   │   ├── pixtral_12b_2409_super_bowl_search_20250307_164721.json
│   │   │   ├── pixtral_12b_2409_super_bowl_search_20250307_164721.md
│   │   │   ├── pixtral_large_latest_super_bowl_search_20250307_164312.json
│   │   │   ├── pixtral_large_latest_super_bowl_search_20250307_164312.md
│   │   │   ├── pixtral_large_latest_super_bowl_search_20250307_164726.json
│   │   │   └── pixtral_large_latest_super_bowl_search_20250307_164726.md
│   │   └── openai
│   │       ├── gpt_4o_mini_super_bowl_search_20250307_163757.json
│   │       ├── gpt_4o_mini_super_bowl_search_20250307_163757.md
│   │       ├── gpt_4o_mini_super_bowl_search_20250307_164239.json
│   │       ├── gpt_4o_mini_super_bowl_search_20250307_164239.md
│   │       ├── gpt_4o_super_bowl_search_20250307_163741.json
│   │       ├── gpt_4o_super_bowl_search_20250307_163741.md
│   │       ├── gpt_4o_super_bowl_search_20250307_164234.json
│   │       ├── gpt_4o_super_bowl_search_20250307_164234.md
│   │       ├── o1_super_bowl_search_20250307_163809.json
│   │       ├── o1_super_bowl_search_20250307_163809.md
│   │       ├── o3_mini_super_bowl_search_20250307_163820.json
│   │       ├── o3_mini_super_bowl_search_20250307_163820.md
│   │       ├── o3_mini_super_bowl_search_20250307_164245.json
│   │       └── o3_mini_super_bowl_search_20250307_164245.md
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
│       │   ├── test_fast_looping.py
│       │   ├── test_framework.py
│       │   ├── test_langgraph_multiturn.py
│       │   ├── test_langgraph_multiturn_abstracted.py
│       │   ├── test_providers.py
│       │   ├── test_providers_abstracted.py
│       │   ├── test_random_multimodel.py
│       │   ├── test_random_multimodel_stream.py
│       │   ├── test_simple_multimodel.py
│       │   ├── test_simple_multimodel_stream.py
│       │   ├── test_structured_output.py
│       │   ├── test_structured_output_abstracted.py
│       │   └── test_utils.py
│       ├── results
│       │   ├── basic_flow
│       │   │   ├── final_state.json
│       │   │   ├── interactions.jsonl
│       │   │   └── metadata.json
│       │   ├── confidence_thresholds
│       │   │   ├── final_state.json
│       │   │   ├── interactions.jsonl
│       │   │   └── metadata.json
│       │   ├── error_handling
│       │   │   ├── final_state.json
│       │   │   ├── interactions.jsonl
│       │   │   └── metadata.json
│       │   ├── looping_behavior
│       │   │   ├── final_state.json
│       │   │   ├── interactions.jsonl
│       │   │   └── metadata.json
│       │   └── tool_integration
│       │       ├── final_state.json
│       │       ├── interactions.jsonl
│       │       └── metadata.json
│       ├── test_chorus_endpoints.py
│       ├── test_core_endpoints.py
│       ├── test_main.py
│       ├── test_response_schemas.py
│       ├── test_structured_outputs.py
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
│           ├── test_langgraph_providers.py
│           ├── test_multimodel_with_tools.py
│           ├── test_provider_langgraph.py
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
│   ├── plan_langgraph.md
│   ├── plan_langgraph_postchain.md
│   ├── plan_libsql.md
│   ├── plan_model_config_checklist.md
│   ├── plan_postchain_checklist.md
│   ├── plan_tools_checklist.md
│   ├── scripts
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   ├── tool_api_docs.md
│   └── tree.md
├── notebooks
│   ├── fqaho_simulation.ipynb
│   ├── post_chain0.ipynb
│   └── vowel_loop3.ipynb
├── postchain_tests.log
├── render.yaml
├── reports
│   ├── bind_tools_capability_summary.md
│   ├── search_report_anthropic_20250307_145453.md
│   ├── search_report_anthropic_20250307_150249.md
│   ├── search_report_anthropic_20250307_151027.md
│   ├── search_report_anthropic_20250307_151401.md
│   ├── search_report_anthropic_20250307_152440.md
│   ├── search_report_anthropic_20250307_152654.md
│   ├── search_report_cohere_20250307_145508.md
│   ├── search_report_fireworks_20250307_145512.md
│   ├── search_report_google_20250307_145715.md
│   ├── search_tools_report_20250307_142734.md
│   ├── search_tools_report_20250307_144002.md
│   ├── search_tools_report_20250307_144255.md
│   ├── search_tools_report_20250307_144342.md
│   ├── search_tools_report_20250307_144942.md
│   └── search_tools_report_20250307_145014.md
├── scripts
│   ├── generate_provider_reports.sh
│   ├── generate_quick_search_report.sh
│   ├── generate_search_report.sh
│   └── generate_single_provider_report.sh
├── tests
│   └── postchain
│       └── test_framework.py
└── ~

75 directories, 333 files
