# Choir Development Guide

## Build & Run Commands
- Run API: `docker-compose up --build api`
- Run tests: `cd api && pytest -v`
- Run single test: `cd api && pytest tests/path/to/test_file.py::TestClass::test_function -v`
- Run specific test category: `cd api && pytest -m "unit"` (or "integration")
- Swift tests: Use Xcode's test navigator to run iOS app tests

## Code Style Guidelines
- **Python**: Use type hints, f-strings, async/await for IO operations
- **Swift**: Follow Apple's Swift API Design Guidelines
- **Error Handling**: Use try/except with specific exceptions in Python, do/catch in Swift
- **Imports**: Group standard library, third-party, and local imports
- **Naming**:
  - Python: snake_case for functions/variables, PascalCase for classes
  - Swift: camelCase for variables/functions, PascalCase for types
- **Comments**: Docstrings for classes and functions, inline comments for complex logic
- **Testing**: Write unit tests for core functionality, integration tests for workflows

## Architecture Notes
- PostChain workflow follows AEIOU-Y phases (Action, Experience, Intention, Observation, Understanding, Yield)
- API uses FastAPI, connects with Qdrant (vector DB) and Sui blockchain
- iOS client built with SwiftUI
