# SpecForge (Go Implementation)

> A Unix-style CLI tool for generating high-quality specifications for agentic AI workflows.

**Status**: 🚧 Under active development (Phase 1)

## Quick Start

```bash
# Clone and build
git clone https://github.com/azmaveth/specforge.git
cd specforge/go
make build

# Configure
cp .env.example .env
# Edit .env and add your LLM API keys

# Run
./spec generate "Implement JWT authentication"
```

## What is SpecForge?

SpecForge generates structured specifications (task specs, system designs, implementation plans) using LLM providers. It's designed to be:

- **Fast**: <5ms startup time, single static binary
- **Composable**: Unix-style pipes and text streams
- **Flexible**: Multiple LLM providers (OpenAI, Anthropic, Ollama, Google)
- **Agent-friendly**: Designed for AI agents (Claude Code, Cursor, etc.)

## Commands

### Generate

```bash
# Generate a task spec
spec generate "Implement user authentication"

# From stdin
echo "Build a blog engine" | spec generate

# From file
spec generate --from requirements.txt

# With specific provider
spec generate "Design API" --model=anthropic:claude-3-5-sonnet

# System design
spec generate "E-commerce platform" --type=system --slice
```

### Transform (Coming Soon)

```bash
# Slice a document
spec transform --slice design.md --outdir=phases/

# Convert format
spec transform --format=json spec.md > spec.json

# Extract tasks
spec transform --extract=tasks design.md
```

### Validate (Coming Soon)

```bash
# Validate a spec
spec validate spec.md

# Lint and score
spec validate --lint --score spec.md
```

## Configuration

SpecForge uses a layered configuration system:

1. Command-line flags (highest priority)
2. Environment variables
3. Config file (`~/.specforge/config.yaml`)
4. Built-in defaults

### Environment Variables

```bash
# LLM API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Default model
SPECFORGE_DEFAULT_MODEL=openai:gpt-4

# Cache settings
SPECFORGE_CACHE_BACKEND=disk
SPECFORGE_CACHE_TTL=24h
```

See `.env.example` for all options.

## Development

### Prerequisites

- Go 1.22+
- Make

### Build

```bash
make build      # Build binary
make install    # Install to $GOPATH/bin
make test       # Run tests
make lint       # Run linters
```

### Project Structure

```
.
├── cmd/spec/          # CLI entry point
├── pkg/               # Public packages
│   ├── config/        # Configuration
│   ├── llm/           # LLM providers
│   ├── generator/     # Spec generation
│   ├── cache/         # Caching layer
│   └── ...
├── internal/          # Private packages
│   ├── cli/           # CLI commands
│   └── util/          # Utilities
└── templates/         # Built-in templates
```

## Roadmap

**Phase 1 (Week 1)** - Foundation ✅ In Progress
- [x] Project setup
- [x] Basic CLI structure
- [ ] Config system
- [ ] OpenAI provider
- [ ] Basic generate command

**Phase 2 (Week 2)** - Core Features
- [ ] Multi-provider support (Anthropic, Ollama, Google)
- [ ] Caching layer
- [ ] Transform command
- [ ] Template system

**Phase 3 (Week 3)** - Advanced
- [ ] Validate command
- [ ] Interactive mode
- [ ] System/Plan generators

**Phase 4 (Week 4+)** - Polish
- [ ] Comprehensive tests
- [ ] Documentation
- [ ] CI/CD
- [ ] v1.0 release

See [docs/GO_IMPLEMENTATION_PLAN.md](../docs/GO_IMPLEMENTATION_PLAN.md) for detailed roadmap.

## Documentation

- [Design Document](../docs/GO_DESIGN.md)
- [Implementation Plan](../docs/GO_IMPLEMENTATION_PLAN.md)

## License

MIT - See [LICENSE](../LICENSE)

## Related Projects

- **Elixir Version**: [../](../) - Original Elixir implementation (reference)
- **ExLLM**: Multi-provider LLM client (Elixir)
- **ExMCP**: MCP server implementation (Elixir)
