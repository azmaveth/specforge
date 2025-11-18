# SpecForge Go - Design Document

> **Version**: 2.0
> **Date**: 2025-01-18
> **Status**: Design Phase
> **Target**: Rewrite in Go for optimal CLI performance and Unix composability

---

## Table of Contents

1. [Vision & Goals](#vision--goals)
2. [Why Go](#why-go)
3. [Core Principles](#core-principles)
4. [Architecture](#architecture)
5. [Command Design](#command-design)
6. [Output Formats](#output-formats)
7. [LLM Integration](#llm-integration)
8. [Caching Strategy](#caching-strategy)
9. [Configuration](#configuration)
10. [Plugin System](#plugin-system-future)
11. [Implementation Roadmap](#implementation-roadmap)

---

## Vision & Goals

**SpecForge** is a Unix-style CLI tool for generating high-quality specifications for agentic AI workflows.

### Primary Goal
Provide **atomic, composable operations** for specification generation that:
- Work seamlessly in pipes and scripts
- Serve both human readers and AI agents
- Follow Unix philosophy (do one thing well)
- Support multiple LLM providers
- Are fast, reliable, and predictable

### Target Users
1. **Developers** - Generate task specs, system designs, implementation plans
2. **AI Agents** - Structured specs for autonomous work (Claude Code, Cursor, etc.)
3. **Teams** - Standardized spec formats for consistent communication
4. **Scripts/CI** - Automated spec generation and validation

### What Changed from v1 (Elixir)

| Aspect | v1 (Elixir) | v2 (Go) |
|--------|-------------|---------|
| **Structure** | Umbrella (3 apps) | Single app |
| **Primary Interface** | CLI + Web | CLI-first (web optional) |
| **Commands** | `task`, `system`, `plan` | `generate`, `transform`, `validate` |
| **Startup Time** | ~150ms | <5ms |
| **Binary Size** | ~50MB (escript) | ~10MB |
| **Concurrency** | OTP/GenServer | Goroutines |
| **Output** | Single docs or slices | Smart hybrid |
| **Distribution** | Requires Erlang or large escript | Single static binary |

---

## Why Go

### Technical Reasons

1. **Startup Time**: 1-5ms vs. 100-150ms (Elixir)
   - Critical for tight loops and scripts
   - Better UX in interactive shells

2. **Distribution**: Single static binary
   - No runtime dependencies
   - Easy install: `curl | tar | mv`
   - Cross-compilation is trivial

3. **CLI Ecosystem**: Industry standard
   - kubectl, docker, terraform, gh, hugo
   - Users expect this performance

4. **Concurrency**: Good enough
   - Goroutines handle parallel LLM calls easily
   - Simpler than async Rust
   - More explicit than Elixir processes

5. **Development Speed**: Fast iteration
   - Quick compilation (~5-30 sec)
   - Simple deployment
   - Easier debugging than Rust

### What We Lose from Elixir

- ❌ Built-in fault tolerance (OTP)
- ❌ Hot code reloading
- ❌ Phoenix web framework
- ❌ Pattern matching elegance

### What We Gain

- ✅ 30x faster startup
- ✅ 5x smaller binaries
- ✅ Easier distribution
- ✅ Better Unix tool UX
- ✅ Larger community for CLI tools

**Verdict**: For a CLI-first tool, Go is the right choice.

---

## Core Principles

### 1. Unix Philosophy

**Do one thing well**
```bash
# Not this (monolithic)
spec build-entire-project --all-phases

# This (atomic operations)
spec generate "project idea" | \
  spec transform --slice | \
  spec validate
```

**Compose via pipes**
```bash
cat ideas.txt | \
  while read idea; do
    spec generate "$idea" --type=task
  done | \
  spec validate --lint | \
  tee validated_specs.json
```

**Text streams as interface**
```bash
# Read from stdin, write to stdout
echo "Implement auth" | spec generate > task.md

# Read from file, write to file
spec generate --from idea.txt --to spec.md

# Pipe to other tools
spec generate "API spec" | openapi-codegen
```

### 2. Progressive Disclosure

**Simple by default**
```bash
spec generate "Build a blog"  # Uses smart defaults
```

**Power when needed**
```bash
spec generate "Build a blog" \
  --type=system \
  --model=anthropic:claude-3-opus \
  --template=custom.tmpl \
  --slice \
  --outdir=phases/ \
  --format=json \
  --no-cache
```

### 3. Stateless Operations

- No hidden global state
- No required daemon (optional for performance)
- Reproducible outputs (same input → same output, if cache disabled)
- Side effects are explicit (files written, cache updates)

### 4. Agent-Friendly Design

**Machine-readable outputs**
```bash
spec generate --format=json  # Structured data
spec transform --extract=tasks | jq '.tasks[] | .title'
```

**Metadata for navigation**
```json
{
  "type": "system_design",
  "phases": [...],
  "entry_points": {
    "human": "design.md",
    "agent": "phases/",
    "tasks": "tasks.json"
  }
}
```

**Tools over formats**
- Agents use `spec transform` to get what they need
- Don't force a single output format
- Let agents compose operations

---

## Architecture

### Project Structure

```
specforge/
├── cmd/
│   └── spec/
│       └── main.go                 # CLI entry point
│
├── pkg/                            # Public packages (importable)
│   ├── generator/
│   │   ├── generator.go           # Core generation logic
│   │   ├── task.go                # Task-specific prompts
│   │   ├── system.go              # System design prompts
│   │   └── plan.go                # Plan generation
│   │
│   ├── llm/                        # LLM provider abstraction
│   │   ├── client.go              # Unified client
│   │   ├── provider.go            # Interface
│   │   ├── openai.go              # OpenAI implementation
│   │   ├── anthropic.go           # Anthropic implementation
│   │   ├── ollama.go              # Ollama implementation
│   │   └── google.go              # Google Gemini
│   │
│   ├── transformer/                # Document transformation
│   │   ├── slicer.go              # Split by sections
│   │   ├── formatter.go           # Format conversion (MD/JSON/YAML)
│   │   ├── extractor.go           # Extract metadata/tasks
│   │   └── merger.go              # Combine specs
│   │
│   ├── validator/                  # Spec validation & quality
│   │   ├── validator.go           # Interface
│   │   ├── linter.go              # Check for issues
│   │   ├── scorer.go              # Quality scoring
│   │   └── rules.go               # Validation rules
│   │
│   ├── cache/                      # Caching layer
│   │   ├── cache.go               # Interface
│   │   ├── memory.go              # In-memory (default)
│   │   ├── disk.go                # Persistent cache
│   │   └── key.go                 # Key generation
│   │
│   ├── template/                   # Template engine
│   │   ├── engine.go              # Template processing
│   │   └── builtin.go             # Built-in templates
│   │
│   └── config/                     # Configuration
│       ├── config.go              # Config struct & loading
│       └── env.go                 # Environment variables
│
├── internal/                       # Private packages
│   ├── cli/                        # CLI command implementations
│   │   ├── generate.go
│   │   ├── transform.go
│   │   ├── validate.go
│   │   ├── cache.go
│   │   └── daemon.go              # Optional daemon mode
│   │
│   └── util/                       # Internal utilities
│       ├── io.go                  # Input/output helpers
│       ├── hash.go                # Hashing utilities
│       └── logger.go              # Logging
│
├── templates/                      # Built-in templates
│   ├── task.tmpl
│   ├── system.tmpl
│   └── plan.tmpl
│
├── .specforge/                     # Local config (gitignored)
│   └── cache/
│
├── go.mod
├── go.sum
├── Makefile
├── .env.example
└── README.md
```

### Key Dependencies

```go
require (
    github.com/spf13/cobra v1.8.0           // CLI framework
    github.com/spf13/viper v1.18.0          // Configuration
    github.com/charmbracelet/bubbletea v0.25.0  // TUI (interactive mode)
    github.com/charmbracelet/lipgloss v0.9.0    // Styling
    github.com/patrickmn/go-cache v2.1.0    // In-memory cache
    go.uber.org/zap v1.26.0                 // Structured logging
    gopkg.in/yaml.v3 v3.0.1                 // YAML support
)
```

### Design Patterns

**Provider Pattern** (LLM)
```go
type Provider interface {
    Generate(ctx context.Context, req Request) (*Response, error)
    Name() string
    DefaultModel() string
}

// Register providers at runtime
registry.Register("openai", NewOpenAI(cfg))
registry.Register("anthropic", NewAnthropic(cfg))
```

**Strategy Pattern** (Generation Types)
```go
type GenerateStrategy interface {
    BuildPrompt(input string, opts Options) string
    Parse(response string) (Spec, error)
}

// Different strategies for different spec types
strategies := map[string]GenerateStrategy{
    "task":   &TaskStrategy{},
    "system": &SystemStrategy{},
    "plan":   &PlanStrategy{},
}
```

**Middleware/Chain** (Cache, Validation)
```go
// Wrap generator with middleware
gen := NewGenerator(llm)
gen = WithCache(gen, cache)
gen = WithValidation(gen, validator)
gen = WithRetry(gen, 3)
```

---

## Command Design

### Philosophy: Atomic Operations

Instead of workflow-specific commands (`task`, `system`, `plan`), provide **atomic operations** that compose:

1. **generate** - Create specs from prompts
2. **transform** - Modify/convert specs
3. **validate** - Check spec quality
4. **cache** - Manage cache

### Command: `generate`

**Purpose**: Generate specifications from prompts or files

```bash
spec generate [INPUT] [OPTIONS]

# Examples
spec generate "Implement JWT auth"
spec generate --from requirements.txt
echo "Build blog engine" | spec generate
spec generate "API design" --type=openapi
spec generate "System architecture" --slice --outdir=phases/
```

**Flags**:
```
--type=TYPE          Spec type (task, system, plan, api, custom)
--from=FILE          Read input from file
--to=FILE            Write output to file
--model=PROVIDER:MODEL   LLM model (e.g., openai:gpt-4)
--template=FILE      Custom template
--format=FORMAT      Output format (markdown, json, yaml)
--slice              Split into logical sections
--outdir=DIR         Output directory (with --slice)
--no-cache           Disable caching
--no-validate        Skip validation
--interactive        Interactive mode (TUI)
```

**Input Priority**: `--from` > args > stdin

**Output Priority**: `--to` > stdout

### Command: `transform`

**Purpose**: Transform existing specs (slice, format, extract, merge)

```bash
spec transform [OPERATION] [OPTIONS] [FILE]

# Examples
spec transform --slice design.md --outdir=phases/
spec transform --format=json spec.md > spec.json
spec transform --extract=tasks design.md > tasks.json
spec transform --merge spec1.md spec2.md > combined.md
spec transform --summarize design.md > summary.md
```

**Operations**:
```
--slice              Split by sections (## headers)
--format=FORMAT      Convert format (md/json/yaml)
--extract=WHAT       Extract metadata (tasks, phases, sections)
--merge FILES...     Combine multiple specs
--summarize          Create executive summary
```

**Why separate from generate?**
- Atomic operations (Unix philosophy)
- Can work on existing files (not just LLM output)
- Composable in pipes
- Fast (no LLM calls)

### Command: `validate`

**Purpose**: Validate and score spec quality

```bash
spec validate [OPTIONS] [FILE]

# Examples
spec validate spec.md
spec validate --lint spec.md
spec validate --score spec.md
spec validate --schema=custom.json spec.md
cat spec.md | spec validate --lint
```

**Flags**:
```
--lint               Check for common issues
--score              Quality scoring (0-100)
--schema=FILE        Validate against JSON schema
--rules=FILE         Custom validation rules
--fix                Auto-fix issues (where possible)
```

**Exit codes**:
- 0: Valid
- 1: Validation failed
- 2: File not found

**Use in CI**:
```bash
# Fail build if spec quality < 80
spec validate --score spec.md | jq -e '.score >= 80'
```

### Command: `cache`

**Purpose**: Manage LLM response cache

```bash
spec cache [SUBCOMMAND]

# Examples
spec cache list              # Show cached entries
spec cache clear             # Clear all cache
spec cache stats             # Cache statistics
spec cache export > cache.tar.gz
spec cache import < cache.tar.gz
```

**Subcommands**:
```
list                 List cached items
clear                Clear cache
stats                Show statistics (hits, misses, size)
export               Export cache (for sharing)
import               Import cache
prune                Remove old/unused entries
```

### Global Flags

Available on all commands:

```
--model=PROVIDER:MODEL   Override default model
--cache=[mem|disk]       Cache backend (default: mem)
--cache-ttl=DURATION     Cache TTL (default: 1h)
--output-dir=DIR         Default output directory
--config=FILE            Config file path
--quiet, -q              Suppress non-essential output
--verbose, -v            Verbose logging
--help, -h               Help
--version                Version info
```

---

## Output Formats

### Design Philosophy

**Default: Smart Hybrid**
- Single primary document (human-readable)
- Optional metadata file (machine-readable)
- On-demand slicing (via transform)

### Format 1: Default (Single Doc + Metadata)

```bash
spec generate "Build blog platform"
```

**Outputs**:
```
specs/
├── blog_platform.md              # Primary doc (5-15 pages)
└── .specforge/
    └── blog_platform.json        # Metadata
```

**blog_platform.md**:
```markdown
# Blog Platform - System Design

## Overview
[1-2 pages: goals, architecture]

## Phase 1: Foundation
[3-5 pages: detailed phase spec]

## Phase 2: Core Features
[3-5 pages]

## Phase 3: Polish
[3-5 pages]

## Appendix: Decisions
[ADRs, alternatives considered]
```

**blog_platform.json** (metadata):
```json
{
  "type": "system_design",
  "generated_at": "2025-01-18T10:30:00Z",
  "model": "anthropic:claude-3-5-sonnet",
  "input_hash": "abc123...",
  "phases": [
    {
      "id": "phase_1",
      "title": "Foundation",
      "sections": {
        "start_line": 10,
        "end_line": 150
      },
      "estimated_effort": "2 weeks",
      "dependencies": []
    }
  ],
  "entry_points": {
    "human": "blog_platform.md",
    "agent_slice": "phases/",
    "tasks": "tasks.json"
  }
}
```

### Format 2: Sliced (Agent-Optimized)

```bash
spec generate "Build blog" --slice --outdir=phases/
```

**Outputs**:
```
specs/blog_platform/
├── README.md                      # Overview + navigation (1 page)
├── design.md                      # Complete doc (for humans)
├── phases/                        # Sliced by phase (for agents)
│   ├── 01_foundation.md          # 3-5 pages each
│   ├── 02_core_features.md
│   └── 03_polish.md
└── .specforge/
    ├── manifest.json              # Complete metadata
    └── graph.json                 # Dependency graph
```

### Format 3: Structured (JSON/YAML)

```bash
spec generate "Build blog" --format=json
```

**Output**:
```json
{
  "type": "system_design",
  "title": "Blog Platform",
  "overview": {
    "goals": ["...", "..."],
    "architecture": "...",
    "tech_stack": ["Go", "PostgreSQL", "React"]
  },
  "phases": [
    {
      "id": "01_foundation",
      "title": "Foundation & Setup",
      "description": "...",
      "tasks": [
        {
          "id": "task_1",
          "title": "Initialize project",
          "acceptance_criteria": ["...", "..."],
          "estimated_effort": "2 days"
        }
      ],
      "dependencies": []
    }
  ]
}
```

### On-Demand Transformation

```bash
# Start with single doc
spec generate "Build blog" > design.md

# Later, slice as needed
spec transform --slice design.md --outdir=phases/

# Or extract just tasks
spec transform --extract=tasks design.md > tasks.json

# Or convert format
spec transform --format=yaml design.md > design.yaml
```

### Granularity Guidelines

**Good slicing** (5-15 pages per file):
- One logical phase per file
- Complete, standalone thought
- Clear dependencies
- Navigable structure

**Bad slicing** (avoid):
- ❌ Too granular (<2 pages): Fragmented, hard to navigate
- ❌ Too coarse (>20 pages): Lost in the middle problem
- ❌ Arbitrary splits: Mid-section cuts, broken context

### Why This Works

**For Humans**:
- Default single doc is easiest to read
- Can print/share one file
- Natural narrative flow

**For AI Agents**:
- Can slice on-demand for focused context
- Metadata enables smart navigation
- JSON output for structured processing
- Each slice fits comfortably in context window

**For Both**:
- Transform operations are fast (no LLM calls)
- Reproducible (same input → same slices)
- Version control friendly
- Composable with other tools

---

## LLM Integration

### Provider Abstraction

**Interface**:
```go
type Provider interface {
    Generate(ctx context.Context, req Request) (*Response, error)
    Name() string
    DefaultModel() string
    ListModels() ([]Model, error)
}

type Request struct {
    Prompt      string
    Model       string
    Temperature float64
    MaxTokens   int
    Stop        []string
    Stream      bool
}

type Response struct {
    Content   string
    Model     string
    Usage     Usage
    Cached    bool
    Duration  time.Duration
}
```

### Supported Providers

| Provider | API | Models | Notes |
|----------|-----|--------|-------|
| OpenAI | REST | gpt-4, gpt-4-turbo, gpt-3.5-turbo | Default provider |
| Anthropic | REST | claude-3-opus, claude-3-5-sonnet | Best for long docs |
| Ollama | Local | llama3.3, mixtral, codellama | Free, local |
| Google | REST | gemini-1.5-pro, gemini-1.5-flash | Huge context |
| Azure OpenAI | REST | Same as OpenAI | Enterprise |

### Model Selection

**Default fallback chain**:
1. `--model` flag
2. `DEFAULT_MODEL` env var
3. Config file (`~/.specforge/config.yaml`)
4. Built-in default (`openai`)

**Model string format**:
```bash
# Provider only (uses provider's default model)
--model=openai          # → gpt-4-turbo
--model=anthropic       # → claude-3-5-sonnet

# Provider + specific model
--model=openai:gpt-4o
--model=anthropic:claude-3-opus-20240229
--model=ollama:llama3.3:70b
```

### Parallel Requests

For batch operations:

```go
func GenerateBatch(prompts []string) []Result {
    results := make(chan Result, len(prompts))
    sem := make(chan struct{}, 10) // Max 10 concurrent

    var wg sync.WaitGroup
    for _, prompt := range prompts {
        wg.Add(1)
        go func(p string) {
            defer wg.Done()
            sem <- struct{}{}
            defer func() { <-sem }()

            results <- generate(p)
        }(prompt)
    }

    wg.Wait()
    close(results)

    // Collect results...
}
```

**Usage**:
```bash
# Sequential (current)
cat features.txt | while read f; do spec generate "$f"; done

# Parallel (future enhancement)
spec generate --batch features.txt --concurrency=10
```

---

## Caching Strategy

### Why Cache?

- **Cost savings**: LLM API calls are expensive ($0.003-0.03 per 1k tokens)
- **Speed**: Cached responses return instantly
- **Reproducibility**: Same input → same output (deterministic)
- **Offline work**: Use cached results without internet

### Cache Key Generation

```go
func CacheKey(req Request) string {
    // Hash: prompt + model + temperature + other params
    data := fmt.Sprintf("%s:%s:%f:%d",
        req.Prompt,
        req.Model,
        req.Temperature,
        req.MaxTokens,
    )
    hash := sha256.Sum256([]byte(data))
    return hex.EncodeToString(hash[:])
}
```

### Cache Backends

**Memory** (default):
- In-process cache (cleared on exit)
- Fast (no disk I/O)
- Good for development

**Disk**:
- Persistent across runs
- Shareable across team (export/import)
- Good for production

**Configuration**:
```bash
# Memory (default)
spec generate --cache=mem

# Disk
spec generate --cache=disk

# Disable
spec generate --no-cache

# Custom TTL
spec generate --cache-ttl=24h
```

### Cache Directory

```
~/.specforge/cache/
├── memory/              # Temp cache
└── disk/
    ├── abc123.json      # Cached response
    ├── def456.json
    └── index.json       # Cache index
```

### Cache Management

```bash
# View stats
spec cache stats
# Output:
# Hits: 45
# Misses: 12
# Hit rate: 78.9%
# Size: 2.3 MB
# Entries: 57

# List entries
spec cache list
# Output:
# abc123... | 2025-01-18 10:30 | task generation | openai:gpt-4

# Clear cache
spec cache clear

# Export for team
spec cache export > team-cache.tar.gz

# Import
spec cache import < team-cache.tar.gz
```

---

## Configuration

### Precedence (highest to lowest)

1. Command-line flags
2. Environment variables
3. Config file (`~/.specforge/config.yaml`)
4. Built-in defaults

### Config File Format

**~/.specforge/config.yaml**:
```yaml
# Default LLM provider
default_model: "anthropic:claude-3-5-sonnet"

# Provider configurations
providers:
  openai:
    api_key_env: "OPENAI_API_KEY"
    default_model: "gpt-4-turbo"
    timeout: 30s

  anthropic:
    api_key_env: "ANTHROPIC_API_KEY"
    default_model: "claude-3-5-sonnet-20241022"
    timeout: 60s

  ollama:
    host: "http://localhost:11434"
    default_model: "llama3.3"

# Cache settings
cache:
  backend: "disk"
  ttl: "24h"
  max_size: "1GB"

# Output settings
output:
  dir: "./specs"
  format: "markdown"
  auto_slice: false

# Validation settings
validation:
  enabled: true
  min_score: 70
  strict: false

# Logging
log:
  level: "info"
  format: "text"
```

### Environment Variables

```bash
# LLM Provider API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...

# Default model
SPECFORGE_DEFAULT_MODEL=anthropic:claude-3-5-sonnet

# Cache
SPECFORGE_CACHE_BACKEND=disk
SPECFORGE_CACHE_TTL=24h

# Output
SPECFORGE_OUTPUT_DIR=./specs

# Logging
SPECFORGE_LOG_LEVEL=info
```

### .env File Support

```bash
# .env (gitignored)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
SPECFORGE_DEFAULT_MODEL=openai:gpt-4
```

Automatically loaded if present in current directory.

---

## Plugin System (Future)

### Goals

- Allow custom spec types
- Organization-specific templates
- Custom validation rules
- Extensibility without forking

### Plugin Interface (Draft)

```go
type Plugin interface {
    Name() string
    Type() string  // "generator", "validator", "transformer"
    Execute(ctx context.Context, input Input) (Output, error)
}

// Example: Custom generator plugin
type APISpecGenerator struct{}

func (g *APISpecGenerator) Name() string { return "api-spec" }
func (g *APISpecGenerator) Type() string { return "generator" }

func (g *APISpecGenerator) Execute(ctx context.Context, input Input) (Output, error) {
    // Custom logic for generating OpenAPI specs
    return generateOpenAPISpec(input.Prompt)
}
```

### Plugin Loading

```bash
# User plugins directory
~/.specforge/plugins/
├── api-spec.so
└── team-validator.so

# Use custom type
spec generate "REST API for users" --type=api-spec
```

### Distribution

Plugins as Go shared objects (.so) or standalone binaries that implement a protocol (gRPC/stdio).

**Note**: This is future work, not MVP.

---

## Implementation Roadmap

See [GO_IMPLEMENTATION_PLAN.md](./GO_IMPLEMENTATION_PLAN.md) for detailed roadmap.

**Summary**:

### Phase 1: Foundation (Week 1)
- Project setup, basic CLI structure
- Config loading, LLM client (OpenAI only)
- Simple generate command

### Phase 2: Core Features (Week 2)
- All LLM providers
- Transform command (slice, format)
- Caching layer
- Template system

### Phase 3: Advanced (Week 3)
- Validate command
- Interactive mode (TUI)
- Batch operations
- Better error handling

### Phase 4: Polish (Week 4+)
- Comprehensive tests
- Documentation
- CI/CD
- Release automation

---

## Success Metrics

**Functional**:
- ✅ Generates high-quality specs (validated against Elixir output)
- ✅ Supports 4+ LLM providers
- ✅ All atomic operations work (generate, transform, validate)
- ✅ Composable in Unix pipes

**Performance**:
- ✅ Startup time <5ms
- ✅ Binary size <15MB
- ✅ Cache hit latency <1ms

**UX**:
- ✅ Intuitive CLI (0 docs needed for basic usage)
- ✅ Helpful error messages
- ✅ Works offline (with cache/templates)

**Quality**:
- ✅ Test coverage >80%
- ✅ No critical bugs
- ✅ Works on Linux, macOS, Windows

---

## References

- [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy)
- [12 Factor CLI Apps](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46)
- [Cobra CLI Framework](https://github.com/spf13/cobra)
- [ExLLM (Elixir reference)](https://github.com/thmsmlr/ex_llm)

---

**End of Design Document**
