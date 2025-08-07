AGENT quickstart for Choir

- Build/run API: from root `docker-compose up --build api` or from [api](file:///Users/wiz/Choir/api) `uv sync && uv run uvicorn main:app --reload` (health at `/health`).
- Test API: `cd api && uv sync && uv run pytest -v`; single file `uv run pytest -v tests/test_user_thread_endpoints.py`; single test `uv run pytest -v tests/test_user_thread_endpoints.py::test_create_thread`.
- Pytest markers: unit/integration enabled via [pytest.ini](file:///Users/wiz/Choir/api/pytest.ini) (use `-m unit` or `-m integration`). Asyncio is strict in [pyproject.toml](file:///Users/wiz/Choir/api/pyproject.toml).
- iOS build/tests: open Xcode project [Choir.xcodeproj](file:///Users/wiz/Choir/Choir.xcodeproj) or CLI: `cd Choir && xcodebuild test -scheme Choir -destination 'platform=iOS Simulator,name=iPhone 15'`.
- Lint/format: no explicit tools configured. For Python, follow PEP8; if adding, prefer `ruff` and `black` via `uv run ruff check` / `uv run black .`. For Swift, prefer SwiftLint if introduced.

Architecture
- Backend: FastAPI app in [main.py](file:///Users/wiz/Choir/api/main.py) mounting routers under `/api/*`: [auth.py](file:///Users/wiz/Choir/api/app/routers/auth.py), [threads.py](file:///Users/wiz/Choir/api/app/routers/threads.py), [users.py](file:///Users/wiz/Choir/api/app/routers/users.py), [balance.py](file:///Users/wiz/Choir/api/app/routers/balance.py), [postchain.py](file:///Users/wiz/Choir/api/app/routers/postchain.py), [vectors.py](file:///Users/wiz/Choir/api/app/routers/vectors.py), [notifications.py](file:///Users/wiz/Choir/api/app/routers/notifications.py). Static and markdown-templated pages via Jinja2.
- Data: Qdrant vector DB via [database.py](file:///Users/wiz/Choir/api/app/database.py) with collections: `choir`, `chat_threads`, `users`, `notifications`. Config/env in [config.py](file:///Users/wiz/Choir/api/app/config.py). Sui blockchain via `pysui` (keys from env). APNs config supported.
- Services and utils live under [app/services](file:///Users/wiz/Choir/api/app/services) and [app/tools](file:///Users/wiz/Choir/api/app/tools); models under [app/models](file:///Users/wiz/Choir/api/app/models).
- iOS app: SwiftUI client in [Choir](file:///Users/wiz/Choir/Choir). Networking via [PostchainAPIClient.swift](file:///Users/wiz/Choir/Choir/Networking/PostchainAPIClient.swift) with async/await and SSE streaming; tests in [ChoirTests](file:///Users/wiz/Choir/ChoirTests).
- Smart contracts: Sui Move sources in [choir_coin](file:///Users/wiz/Choir/choir_coin/choir_coin).

Code style
- Python: type hints required, `snake_case` for funcs/vars, `PascalCase` for classes, f-strings, specific exceptions; validate via Pydantic models; avoid logging secrets. Follow API response envelope types; prefer dependency injection over globals when feasible.
- Swift: Swift API Design Guidelines; `camelCase` for members, `PascalCase` for types; prefer `async/await`, `Result` or throwing APIs; model API responses with Codable and typed errors.

Other rules/docs
- See [README.md](file:///Users/wiz/Choir/README.md) for overview and commands and [CLAUDE.md](file:///Users/wiz/Choir/CLAUDE.md) for agent guidelines. No Cursor/Windsurf/Cline/Goose/Copilot rules present.
