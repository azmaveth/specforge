# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpecForge is an Elixir umbrella project that implements a next-generation task and design specification assistant. It consists of three applications:

- **specforge_core**: Core domain logic, LLM adapters, and caching functionality
- **specforge_cli**: Owl-based command-line interface 
- **specforge_web**: Phoenix web interface and MCP server

The project aims to provide both CLI and web interfaces for generating task specifications and system designs using LLM capabilities.

## Development Commands

### Setup and Dependencies
```bash
# Install dependencies for all apps
mix deps.get

# Setup Phoenix assets (from project root)
cd apps/specforge_web && mix assets.setup
```

### Running the Applications

```bash
# Run Phoenix web server (from project root)
cd apps/specforge_web && mix phx.server
# Access at http://localhost:4000

# Run tests for all apps
mix test

# Run tests for a specific app
cd apps/specforge_core && mix test
cd apps/specforge_cli && mix test  
cd apps/specforge_web && mix test

# Build CLI escript (when implemented)
cd apps/specforge_cli && mix escript.build
```

### Phoenix-specific Commands

```bash
# From apps/specforge_web directory:

# Install JavaScript dependencies
npm install --prefix assets

# Build assets for development  
mix assets.build

# Build assets for production
mix assets.deploy

# Run development server with live reload
mix phx.server
```

## Architecture Overview

### Umbrella Structure
The project uses Elixir's umbrella application pattern to separate concerns:

1. **Core Logic** (`apps/specforge_core/`): Contains behavior modules for task planning, system design, and plan generation. This is where LLM integration (via ex_llm) and caching (likely Cachex) will be implemented.

2. **CLI Interface** (`apps/specforge_cli/`): Implements the command-line interface using Owl for interactive prompts and progress displays. Will provide commands: `spec task`, `spec system`, and `spec plan`.

3. **Web Interface** (`apps/specforge_web/`): Phoenix application providing REST API endpoints and potentially LiveView for interactive features. Configured without Ecto as persistence is optional.

### Key Design Patterns

- **Behaviour-based design**: Core modules will define behaviours that can be implemented with different adapters
- **Stateless operations**: Both CLI and web interfaces designed to be stateless by default
- **Progressive disclosure**: Simple defaults with advanced options available via flags

### Integration Points

- **LLM Integration**: Will use local `ex_llm` library (path dependency)
- **MCP Server**: Will use local `ex_mcp` library for AI agent interoperability
- **Caching**: Cachex for ETS-backed caching with TTL support

## Current Status

According to TASKS.md:
- ✅ Core and CLI apps created
- ✅ Web app created with Phoenix (no Ecto)
- ⏳ Pending: LLM integration, behavior implementations, CLI commands, API endpoints

## Development Notes

- The project is in early implementation phase following the roadmap in SPECFORGE.md
- Phoenix was generated without Ecto as database persistence is optional for MVP
- Configuration uses standard Elixir umbrella patterns with shared deps and config