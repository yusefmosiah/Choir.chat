# Choir Codebase Guide

## Documentation-Driven Development
This project uses a 5-level documentation structure:
- **Level -1**: System files (tree.md, CHANGELOG.md, scripts)
- **Level 0**: Basic integration (client, sui, proxy, carousel prefixes)
- **Level 1**: Core system components (core, Tech, Dev, Service, Coordinator prefixes)
- **Level 2**: Business/implementation (e_, reward_, Error_, Impl_ prefixes)
- **Level 3**: State/economic models (plan_, state_, economic_ prefixes)
- **Level 4**: Theory/simulations (fqaho_, theory_, Model_ prefixes)
- **Level 5**: Foundational principles (evolution_, data_, harmonic_ prefixes)

## Commands
- **API Tests**: `cd api && pytest` (specific test: `pytest tests/test_file.py::test_function`)
- **API Run**: `cd api && uvicorn main:app --reload`
- **Docker**: `docker-compose up`
- **iOS Build/Test**: Xcode shortcuts ⌘B (build) and ⌘U (test)

## Code Style
- **Python**: PEP 8 conventions, FastAPI framework, Pydantic models
- **Swift**: MVVM architecture, SwiftUI, Coordinators pattern
- **Move**: Used for Sui blockchain integration (choir_coin)

## Documentation Updates
Run `./docs/scripts/combiner.sh` to organize documentation by level