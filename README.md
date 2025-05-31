# SpecForge

> ⚠️ **Alpha Software**: This project is currently in alpha stage (v0.1.0).
> The API is unstable and may change significantly before v1.0 release.

## Next-Generation Task & Design Spec Assistant

SpecForge is an AI-powered tool that helps developers analyze tasks, create system designs, and generate implementation plans. Built with Elixir and leveraging multiple LLM providers, it provides both CLI and web interfaces for comprehensive development workflow assistance.

## Features

- 🤖 **Multi-LLM Support**: Works with OpenAI, Anthropic, Ollama, Google Gemini, and more
- 📋 **Task Analysis**: Break down complex tasks into actionable plans
- 🏗️ **System Design**: Create and refine system architectures
- 📝 **Implementation Planning**: Convert designs into detailed development tasks
- 🔄 **Interactive Mode**: Guided interviews for system design
- 🌐 **Web API**: RESTful endpoints for integration
- 📦 **Standalone CLI**: Single executable for easy distribution
- 💾 **Smart Caching**: Reduce API costs with intelligent response caching

## Installation

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- Node.js 18+ (for web interface assets)

### Quick Start

1. **Clone and setup**:

   ```bash
   git clone https://github.com/your-org/specforge.git
   cd specforge
   ./bin/setup
   ```

2. **Configure environment**:

   ```bash
   cp .env.example .env
   # Edit .env with your LLM API keys
   ```

3. **Build CLI executable**:

   ```bash
   ./bin/build-cli
   ```

4. **Test installation**:

   ```bash
   ./spec --version
   ./spec --help
   ```

## Usage

### CLI Commands

**Analyze a task**:

```bash
./spec task "Implement user authentication with JWT tokens"
```

**Interactive system design**:

```bash
./spec system --interactive
```

**Generate implementation plan**:

```bash
./spec plan --from design.md --slice --dir phases/
```

### Web Interface

Start the web server:

```bash
PHX_SERVER=true mix phx.server
```

Visit `http://localhost:4000` for the web interface.

### API Endpoints

- `POST /api/tasks` - Analyze tasks
- `POST /api/systems` - Create system designs  
- `POST /api/plans` - Generate implementation plans
- `GET /api/status/:job_id` - Check job status

## Configuration

SpecForge supports multiple LLM providers through environment variables:

### OpenAI

```bash
OPENAI_API_KEY=sk-your-key-here
DEFAULT_MODEL=openai:gpt-4
```

### Anthropic Claude

```bash
ANTHROPIC_API_KEY=your-key-here
DEFAULT_MODEL=anthropic:claude-3-sonnet
```

### Local Ollama

```bash
OLLAMA_HOST=http://localhost:11434
DEFAULT_MODEL=ollama:llama2
```

### Caching & Output

```bash
CACHE_BACKEND=mem              # mem or disk
CACHE_TTL=3600                # seconds
OUTPUT_DIR=./specs            # output directory
```

See `.env.example` for complete configuration options.

## Development

### Project Structure

```text
specforge/
├── apps/
│   ├── specforge_core/     # Core business logic and LLM integration
│   ├── specforge_cli/      # Command-line interface
│   └── specforge_web/      # Phoenix web application
├── bin/
│   ├── setup              # Development setup script
│   └── build-cli          # CLI build script
├── config/                # Environment configuration
└── docs/                  # Documentation
```

### Core Modules

- **TaskPlanner**: Analyzes tasks and generates actionable plans
- **SystemDesigner**: Creates and refines system architectures
- **PlanGenerator**: Converts designs into implementation tasks
- **Cache**: Smart caching layer for LLM responses

### Running Tests

```bash
mix test                   # Run all tests
mix test --cover          # With coverage
mix credo                 # Code quality
mix dialyzer              # Type checking
mix sobelow               # Security analysis
```

### Building Releases

**Development**:

```bash
mix deps.get
mix compile
```

**Production CLI**:

```bash
./bin/build-cli
```

**Production Release**:

```bash
MIX_ENV=prod mix release
```

**Docker**:

```bash
docker build -t specforge .
docker run -p 4000:4000 specforge
```

## Architecture

SpecForge is built as an Elixir umbrella project with three main applications:

1. **SpecForge Core** - Business logic, LLM integration, caching
2. **SpecForge CLI** - Command-line interface using Owl
3. **SpecForge Web** - Phoenix web application with REST API

The system uses:

- **ExLLM** for unified LLM provider access
- **Cachex** for intelligent response caching
- **OTP** for fault-tolerant concurrent processing
- **Phoenix** for web interface and API
- **Escript** for standalone CLI distribution

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow [Conventional Commits](https://conventionalcommits.org/) for commit messages.

## Roadmap

- [x] Core LLM integration
- [x] CLI interface with escript build
- [x] Web API with async job processing
- [x] Multi-provider LLM support
- [x] Intelligent caching system
- [ ] Web search integration
- [ ] Custom template support
- [ ] MCP server implementation
- [ ] Phoenix LiveDashboard
- [ ] Performance benchmarks

See [TASKS.md](TASKS.md) for detailed progress tracking.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.
