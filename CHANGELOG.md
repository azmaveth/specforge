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
  - Mox for creating test mocks
  - StreamData for property-based testing
- Phoenix API implementation:
  - RESTful API controllers for task, system, and plan operations
  - Async job processing with ETS-based job tracking
  - Status endpoint for job monitoring
  - Fallback controller for error handling
- Test infrastructure:
  - ExUnit test setup with Mox mocks
  - Property-based tests using StreamData
  - Test case base module with helpers
  - Unit tests for TaskPlannerImpl
- Developer setup script (bin/setup) with:
  - Prerequisite checking
  - Dependency installation
  - Environment file creation
  - Asset compilation support
- Basic project documentation (README.md, CLAUDE.md, TASKS.md)
- CI/CD configuration:
  - GitHub Actions workflow for testing across Elixir/OTP versions
  - Automated release workflow with binary artifacts
  - Docker build and push automation
  - Credo and Sobelow integration in CI
- Docker support:
  - Multi-stage Dockerfile for optimized images
  - .dockerignore for efficient builds
- Environment configuration:
  - Comprehensive .env.example file
  - Support for multiple LLM providers
  - Configurable cache and output settings

### Changed
- Moved design documents to `docs/` folder

### Deprecated

### Removed

### Fixed
- Phoenix generation issue with existing file conflict (manually resolved)

### Security

## [0.1.0] - TBD

Initial alpha release.