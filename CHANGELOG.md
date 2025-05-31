# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial umbrella project structure with three applications:
  - `specforge_core` - Core domain logic and LLM integration
  - `specforge_cli` - Command-line interface with Owl
  - `specforge_web` - Phoenix web interface and MCP server
- Core behaviour modules for task planning and system design:
  - `SpecforgeCore.TaskPlanner` - Implements 'spec task' verb
  - `SpecforgeCore.SystemDesigner` - Implements 'spec system' verb
  - `SpecforgeCore.PlanGenerator` - Implements 'spec plan' verb
  - `SpecforgeCore.Slicer` - Document splitting functionality
- Stub implementations for all core behaviours
- CLI implementation with Owl:
  - Main entry point with subcommand routing
  - `spec task` command for task analysis
  - `spec system` command for system design
  - `spec plan` command for implementation planning
  - Colorful help screens and progress indicators
  - Escript configuration for building executable
- Integration with local `ex_llm` and `ex_mcp` libraries
- Cachex dependency for caching support
- Owl dependency for interactive CLI features
- Development tools:
  - Credo for code linting (.credo.exs configuration)
  - Dialyxir for static type checking
  - Sobelow for security scanning
  - ExDoc for documentation generation
- Basic project documentation (README.md, CLAUDE.md, TASKS.md)

### Changed
- Moved design documents to `docs/` folder

### Deprecated

### Removed

### Fixed
- Phoenix generation issue with existing file conflict (manually resolved)

### Security

## [0.1.0] - TBD

Initial alpha release.