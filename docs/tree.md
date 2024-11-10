# Choir-Collective Directory Structure
## Output of $ tree -I 'venv|node_modules|target|archive' | pbcopy

.
├── AIResponse-old.tsx.old
├── ChoirChat-old.tsx.old
├── ChorusPanel-old.tsx.old
├── Dockerfile
├── LICENSE
├── README.md
├── anchor
│   ├── Anchor.toml
│   ├── Cargo.lock
│   ├── Cargo.toml
│   ├── migrations
│   │   └── deploy.ts
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── programs
│   │   └── basic
│   │       ├── Cargo.toml
│   │       ├── Xargo.toml
│   │       └── src
│   │           └── lib.rs
│   ├── src
│   │   ├── basic-exports.ts
│   │   ├── index.ts
│   │   └── types.ts
│   ├── tests
│   │   └── basic.spec.ts
│   ├── trident-tests
│   │   └── fuzz_tests
│   │       └── fuzz_0
│   │           └── test_fuzz.rs
│   └── tsconfig.json
├── api
│   ├── Dockerfile
│   ├── __init__.py
│   ├── app
│   │   ├── __init__.py
│   │   ├── chorus_cycle.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py
│   │   ├── utils.py
│   │   └── websocket_handler.py
│   ├── main.py
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── tests
│       └── test_main.py
├── contracts
│   ├── ChoirToken.sol
│   ├── ChoirToken.vy
│   ├── MessageApproval.sol
│   ├── MessageApproval.vy
│   ├── Thread.sol
│   └── Thread.vy
├── docker-compose.yml
├── docs
│   ├── CHANGELOG.md
│   ├── Impl_Security.md
│   ├── Meta_Evolution.md
│   ├── Model_Foundation_Evolution.md
│   ├── Model_Metastability.md
│   ├── core_architecture.md
│   ├── core_chorus.md
│   ├── core_core.md
│   ├── core_economics.md
│   ├── core_knowledge.md
│   ├── core_patterns.md
│   ├── core_state.md
│   ├── core_state_transitions.md
│   ├── data_engine_model.md
│   ├── docs_operators.md
│   ├── e_business.md
│   ├── e_concept.md
│   ├── e_questions.md
│   ├── e_reference.md
│   ├── goal_architecture.md
│   ├── goal_evolution.md
│   ├── goal_implementation.md
│   ├── harmonic_intelligence.md
│   ├── levels
│   │   ├── level-1.md
│   │   ├── level0.md
│   │   ├── level1.md
│   │   ├── level2.md
│   │   ├── level3.md
│   │   ├── level4.md
│   │   ├── level5.md
│   │   └── level_organization.md
│   ├── plan_post-training.md
│   ├── plan_thoughtspace.md
│   ├── plan_tokenomics.md
│   ├── prompt_chorus_cycle.md
│   ├── prompt_getting_started.md
│   ├── prompt_reentry.md
│   ├── prompt_summary_prompt.md
│   ├── prompt_wake_up.md
│   ├── reward_model.md
│   ├── scripts
│   │   ├── archive_web_stack.sh
│   │   ├── combiner.sh
│   │   └── update_tree.sh
│   ├── self_creation_process.md
│   ├── theory_choir_harmonics.md
│   ├── theory_dynamics.md
│   ├── theory_economics.md
│   ├── theory_foundation.md
│   ├── theory_harmonic_intelligence.md
│   ├── theory_oscillator_cooling.md
│   ├── theory_theory.md
│   └── tree.md
├── jest.config.js
├── jest.setup.js
├── next.config.mjs
├── notebooks
│   └── qdrant.ipynb
├── package.json
├── postcss.config.mjs
├── public
│   └── logo.png
├── src
│   ├── app
│   │   ├── __tests__
│   │   │   └── page.test.tsx
│   │   ├── account
│   │   │   ├── [address]
│   │   │   │   └── page.tsx
│   │   │   └── page.tsx
│   │   ├── api
│   │   │   ├── env-info
│   │   │   │   └── route.ts
│   │   │   └── hello
│   │   │       └── route.ts
│   │   ├── basic
│   │   │   └── page.tsx
│   │   ├── clusters
│   │   │   └── page.tsx
│   │   ├── favicon.ico
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── react-query-provider.tsx
│   ├── components
│   │   ├── AIResponse
│   │   │   └── AIResponse.tsx
│   │   ├── ChoirChat
│   │   │   ├── ChoirChat.tsx
│   │   │   └── MessageFlow.tsx
│   │   ├── ChorusPanel
│   │   │   └── ChorusPanel.tsx
│   │   ├── PriorCard
│   │   │   └── PriorCard.tsx
│   │   ├── PriorPanel
│   │   │   └── PriorPanel.tsx
│   │   ├── ThreadList
│   │   │   └── ThreadList.tsx
│   │   ├── UserInput
│   │   │   └── UserInput.tsx
│   │   ├── account
│   │   │   ├── account-data-access.tsx
│   │   │   ├── account-detail-feature.tsx
│   │   │   ├── account-list-feature.tsx
│   │   │   └── account-ui.tsx
│   │   ├── basic
│   │   │   ├── basic-data-access.tsx
│   │   │   ├── basic-feature.tsx
│   │   │   └── basic-ui.tsx
│   │   ├── cluster
│   │   │   ├── cluster-data-access.tsx
│   │   │   ├── cluster-feature.tsx
│   │   │   └── cluster-ui.tsx
│   │   ├── dashboard
│   │   │   └── dashboard-feature.tsx
│   │   ├── solana
│   │   │   └── solana-provider.tsx
│   │   └── ui
│   │       └── ui-layout.tsx
│   ├── config
│   │   └── index.ts
│   ├── contexts
│   │   └── WalletContextProvider.tsx
│   ├── hooks
│   │   ├── useChorusCycle.ts
│   │   ├── useSolana.ts
│   │   ├── useThread.ts
│   │   └── useWebSocket.ts
│   ├── mocks
│   │   └── mockWebSocket.ts
│   ├── pages
│   │   └── _app.tsx
│   ├── test-utils.tsx
│   └── types
│       ├── index.ts
│       └── jest.d.ts
├── tailwind.config.ts
└── tsconfig.json

50 directories, 146 files
