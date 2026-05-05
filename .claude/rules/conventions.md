## Python

- Target: Python 3.11+
- Linting: Ruff (line-length 100)
- Type hints on all function signatures
- Use `async def` for all FastAPI route handlers
- Use pydantic models for request/response schemas
- Pack builder scripts are numbered (01-05) and run sequentially

## Swift

- Target: iOS 17+, Swift 5.9
- UI framework: SwiftUI
- Use NavigationStack (not deprecated NavigationView)
- XcodeGen `project.yml` is the source of truth for the Xcode project — regenerate after adding/removing files

## General

- Keep CLAUDE.md updated when adding new commands, conventions, or architectural changes
- No documentation files unless explicitly requested
- Prefer editing existing files over creating new ones
