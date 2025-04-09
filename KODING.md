# KODING.md

This file provides guidelines for agentic coding agents working in the Choir repository.

## Project Structure

- `api/`: Python FastAPI backend using LangChain for the PostChain workflow.
- `Choir/`: Swift iOS client application.
- `choir_coin/`: Sui Move smart contract for the CHIP token.
- `docs/`: Project documentation.
- `notebooks/`: Jupyter notebooks for experimentation.

## Commands

**Python API (in `api/` directory):**

- **Run server:** `docker-compose up --build api` (from root directory)
- **Run tests:** `pytest -v`
- **Run single test file:** `pytest -v tests/path/to/test_file.py`
- **Run single test function:** `pytest -v tests/path/to/test_file.py::test_function_name`
- **Lint/Format:** (Not specified, assume `black` and `ruff` or `flake8` might be used, check `pyproject.toml` or ask)

**Swift iOS App (in root directory):**

- **Build:** The developer uses Xcode to build the app manually.
- **Test:** the developer uses Xcode to run tests manually.
- **Lint/Format:** (Not specified, assume SwiftLint might be used, check project settings or ask)

## Code Style

**Python (API):**

- Follow PEP 8 guidelines.
- Use type hints extensively (`typing` module).
- Prefer f-strings for string formatting.
- Use `pydantic` for data validation and settings management.
- LangChain: Follow LangChain's conventions for chains, nodes, and state management.
- Error Handling: Use specific exception types where possible. Log errors appropriately.
- Naming: Use `snake_case` for variables and functions, `PascalCase` for classes.

**Swift (iOS App):**

- Follow Swift API Design Guidelines.
- Use SwiftUI for UI development.
- Prefer `async/await` for concurrency.
- Naming: Use `camelCase` for variables and functions, `PascalCase` for types (structs, classes, enums, protocols).
- Error Handling: Use Swift's `Error` protocol and `do-catch` blocks or `Result` type.

## General

- Check `README.md` for setup and high-level overview.
- Examine existing code in the relevant directory (`api/` or `Choir/`) before adding new features to maintain consistency.
- Update documentation in `docs/` when making significant changes to architecture or core concepts.
