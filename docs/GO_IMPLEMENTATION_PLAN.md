# SpecForge Go - Implementation Plan

> **Status**: Ready to implement
> **Target**: 4 weeks to MVP
> **Approach**: Iterative, test-driven, ship early

---

## Overview

This document provides a step-by-step implementation plan for building SpecForge in Go. Each phase builds on the previous, with working software at each milestone.

---

## Phase 1: Foundation (Week 1)

**Goal**: Basic CLI that can generate a simple spec using OpenAI

### Milestone 1.1: Project Setup (Day 1)

**Tasks**:
- [ ] Initialize Go module
- [ ] Set up directory structure
- [ ] Configure dependencies (cobra, viper, zap)
- [ ] Create Makefile for common tasks
- [ ] Set up .env.example
- [ ] Configure .gitignore

**Deliverable**: `go build` succeeds, `spec --version` works

**Files to create**:
```
go.mod
go.sum
Makefile
.env.example
.gitignore
cmd/spec/main.go
```

**Commands**:
```bash
cd /home/user/specforge
mkdir specforge-go && cd specforge-go
go mod init github.com/azmaveth/specforge
```

### Milestone 1.2: Config System (Day 1-2)

**Tasks**:
- [ ] Implement config loading (viper)
- [ ] Environment variable support
- [ ] .env file loading
- [ ] Config struct definition
- [ ] Default values

**Deliverable**: Config loads from .env and env vars

**Files to create**:
```
pkg/config/config.go
pkg/config/env.go
```

**Test**:
```bash
OPENAI_API_KEY=test spec generate --help  # Should load config
```

### Milestone 1.3: Basic CLI Structure (Day 2)

**Tasks**:
- [ ] Root command with cobra
- [ ] Global flags (--model, --quiet, --verbose)
- [ ] Help system
- [ ] Version command
- [ ] Logging setup (zap)

**Deliverable**: CLI skeleton with help and flags

**Files to create**:
```
internal/cli/root.go
internal/cli/version.go
internal/util/logger.go
```

**Test**:
```bash
spec --help
spec --version
spec --verbose generate --help
```

### Milestone 1.4: OpenAI Provider (Day 3)

**Tasks**:
- [ ] Define Provider interface
- [ ] Implement OpenAI provider
- [ ] HTTP client with timeout/retry
- [ ] Request/Response structs
- [ ] Error handling
- [ ] Unit tests

**Deliverable**: Can make OpenAI API calls

**Files to create**:
```
pkg/llm/provider.go
pkg/llm/client.go
pkg/llm/openai.go
pkg/llm/openai_test.go
```

**Test**:
```go
// Manual test
client := llm.NewOpenAI(cfg)
resp, err := client.Generate(ctx, llm.Request{
    Prompt: "Say hello",
    Model: "gpt-4-turbo",
})
fmt.Println(resp.Content)
```

### Milestone 1.5: Basic Generator (Day 4)

**Tasks**:
- [ ] Generator struct
- [ ] Task generation prompt
- [ ] Template for task specs
- [ ] Basic output formatting

**Deliverable**: Can generate a task spec

**Files to create**:
```
pkg/generator/generator.go
pkg/generator/task.go
templates/task.tmpl
```

**Test**:
```go
gen := generator.New(llmClient)
spec, err := gen.GenerateTask(ctx, "Implement JWT auth")
```

### Milestone 1.6: Generate Command (Day 5)

**Tasks**:
- [ ] Implement generate command
- [ ] Input handling (args, stdin, --from)
- [ ] Output handling (stdout, --to)
- [ ] Progress indicators
- [ ] Error messages

**Deliverable**: Working `spec generate` command

**Files to create**:
```
internal/cli/generate.go
internal/util/io.go
```

**Test**:
```bash
spec generate "Implement user authentication"
echo "Build a blog" | spec generate
spec generate --from idea.txt --to spec.md
```

### Phase 1 Deliverable

✅ **Working MVP**: `spec generate` creates task specs using OpenAI

**Demo**:
```bash
export OPENAI_API_KEY=sk-...
spec generate "Implement JWT authentication with refresh tokens"
# Outputs a detailed task specification
```

---

## Phase 2: Core Features (Week 2)

**Goal**: Multi-provider support, caching, transformations

### Milestone 2.1: Additional LLM Providers (Day 6-7)

**Tasks**:
- [ ] Anthropic provider
- [ ] Ollama provider (local)
- [ ] Google Gemini provider
- [ ] Provider registry
- [ ] Model string parsing (provider:model)
- [ ] Provider auto-detection

**Deliverable**: Support 4 LLM providers

**Files to create**:
```
pkg/llm/anthropic.go
pkg/llm/ollama.go
pkg/llm/google.go
pkg/llm/registry.go
```

**Test**:
```bash
spec generate "task" --model=anthropic:claude-3-5-sonnet
spec generate "task" --model=ollama:llama3.3
spec generate "task" --model=google:gemini-1.5-pro
```

### Milestone 2.2: Caching Layer (Day 7-8)

**Tasks**:
- [ ] Cache interface
- [ ] Memory cache implementation
- [ ] Disk cache implementation
- [ ] Cache key generation (SHA256)
- [ ] TTL support
- [ ] Cache stats

**Deliverable**: LLM responses are cached

**Files to create**:
```
pkg/cache/cache.go
pkg/cache/memory.go
pkg/cache/disk.go
pkg/cache/key.go
```

**Test**:
```bash
# First call (slow, hits LLM)
time spec generate "test"  # ~3 seconds

# Second call (fast, from cache)
time spec generate "test"  # ~5ms
```

### Milestone 2.3: Cache Command (Day 8)

**Tasks**:
- [ ] cache list subcommand
- [ ] cache clear subcommand
- [ ] cache stats subcommand
- [ ] cache export/import

**Deliverable**: Cache management CLI

**Files to create**:
```
internal/cli/cache.go
```

**Test**:
```bash
spec cache stats
spec cache list
spec cache clear
```

### Milestone 2.4: Transform - Slicer (Day 9)

**Tasks**:
- [ ] Markdown section detector (## headers)
- [ ] Section extractor
- [ ] File writer with slug generation
- [ ] Directory creation

**Deliverable**: Can slice documents by sections

**Files to create**:
```
pkg/transformer/slicer.go
pkg/transformer/slicer_test.go
```

**Test**:
```bash
spec transform --slice design.md --outdir=phases/
# Creates phases/01_foundation.md, phases/02_features.md, etc.
```

### Milestone 2.5: Transform Command (Day 10)

**Tasks**:
- [ ] transform command with subcommands
- [ ] Format conversion (MD → JSON)
- [ ] Format conversion (MD → YAML)
- [ ] Extract metadata
- [ ] Merge specs

**Deliverable**: Full transform command

**Files to create**:
```
internal/cli/transform.go
pkg/transformer/formatter.go
pkg/transformer/extractor.go
pkg/transformer/merger.go
```

**Test**:
```bash
spec transform --slice design.md
spec transform --format=json spec.md > spec.json
spec transform --extract=tasks spec.md
```

### Phase 2 Deliverable

✅ **Complete Core**: Multi-provider, caching, transformations working

**Demo**:
```bash
# Generate with any provider
spec generate "Build blog" --model=anthropic:claude-3-5-sonnet > design.md

# Slice it
spec transform --slice design.md --outdir=phases/

# Convert format
spec transform --format=json design.md > design.json

# Cache stats
spec cache stats
```

---

## Phase 3: Advanced Features (Week 3)

**Goal**: Validation, system/plan generators, interactive mode

### Milestone 3.1: System Design Generator (Day 11-12)

**Tasks**:
- [ ] System design prompt template
- [ ] Multi-turn conversation (for requirements gathering)
- [ ] Structured output parsing
- [ ] System design specific formatting

**Deliverable**: `spec generate --type=system` works

**Files to create**:
```
pkg/generator/system.go
templates/system.tmpl
```

**Test**:
```bash
spec generate "E-commerce platform" --type=system
```

### Milestone 3.2: Plan Generator (Day 12-13)

**Tasks**:
- [ ] Parse existing design docs
- [ ] Extract phases/sections
- [ ] Task extraction from design
- [ ] Dependency inference
- [ ] Sequencing logic

**Deliverable**: `spec generate --type=plan --from=design.md`

**Files to create**:
```
pkg/generator/plan.go
pkg/transformer/parser.go
templates/plan.tmpl
```

**Test**:
```bash
spec generate --type=plan --from=system_design.md
```

### Milestone 3.3: Validation Framework (Day 13-14)

**Tasks**:
- [ ] Validator interface
- [ ] Linting rules (completeness, clarity)
- [ ] Quality scoring algorithm
- [ ] Fix suggestions
- [ ] JSON schema validation

**Deliverable**: `spec validate` command

**Files to create**:
```
pkg/validator/validator.go
pkg/validator/linter.go
pkg/validator/scorer.go
pkg/validator/rules.go
internal/cli/validate.go
```

**Test**:
```bash
spec validate spec.md
spec validate --lint spec.md
spec validate --score spec.md
```

### Milestone 3.4: Interactive Mode (Day 15)

**Tasks**:
- [ ] Bubbletea TUI integration
- [ ] Interactive prompts
- [ ] Progress display
- [ ] Real-time updates

**Deliverable**: `spec generate --interactive`

**Files to create**:
```
internal/tui/generate.go
internal/tui/model.go
```

**Test**:
```bash
spec generate --interactive
# Shows TUI with prompts and progress
```

### Phase 3 Deliverable

✅ **Feature Complete**: All core features implemented

**Demo**:
```bash
# System design
spec generate "Microservices platform" --type=system --slice

# Plan from design
spec generate --type=plan --from=design.md > plan.md

# Validate
spec validate plan.md --score

# Interactive
spec generate --interactive
```

---

## Phase 4: Polish & Release (Week 4+)

**Goal**: Production-ready, documented, tested, released

### Milestone 4.1: Comprehensive Testing (Day 16-17)

**Tasks**:
- [ ] Unit tests for all packages (>80% coverage)
- [ ] Integration tests
- [ ] CLI command tests
- [ ] Provider mock tests
- [ ] Property-based tests (fuzzing)

**Deliverable**: `go test ./... -cover` shows >80%

**Files to create**:
```
*_test.go files throughout
testdata/ fixtures
```

### Milestone 4.2: Error Handling & UX (Day 17-18)

**Tasks**:
- [ ] Helpful error messages
- [ ] Suggestions for fixes
- [ ] Exit codes
- [ ] Colored output (optional)
- [ ] Spinner for long operations
- [ ] Progress bars

**Deliverable**: Great error UX

**Test**:
```bash
spec generate  # Error: no input provided. Try: spec generate "prompt"
spec generate --model=invalid  # Error: unknown provider "invalid"
```

### Milestone 4.3: Documentation (Day 18-19)

**Tasks**:
- [ ] README with quick start
- [ ] User guide with examples
- [ ] API documentation (godoc)
- [ ] Configuration guide
- [ ] Deployment guide
- [ ] Contributing guide

**Deliverable**: Complete documentation

**Files to create**:
```
README.md
docs/USER_GUIDE.md
docs/CONFIGURATION.md
docs/API.md
CONTRIBUTING.md
```

### Milestone 4.4: Build & Release Automation (Day 19-20)

**Tasks**:
- [ ] Makefile for building
- [ ] Cross-compilation (Linux, macOS, Windows)
- [ ] GitHub Actions CI
- [ ] Release workflow
- [ ] Binary artifacts
- [ ] Homebrew formula (optional)

**Deliverable**: Automated releases

**Files to create**:
```
.github/workflows/ci.yml
.github/workflows/release.yml
Makefile
```

**Test**:
```bash
make build
make test
make release
```

### Milestone 4.5: v1.0 Release (Day 20+)

**Tasks**:
- [ ] Final testing on all platforms
- [ ] Changelog preparation
- [ ] Version tagging
- [ ] GitHub release
- [ ] Announcement

**Deliverable**: v1.0.0 released!

---

## Development Guidelines

### Code Quality Standards

**Formatting**:
```bash
go fmt ./...
go vet ./...
golangci-lint run
```

**Testing**:
```bash
# Run all tests
go test ./...

# With coverage
go test ./... -cover -coverprofile=coverage.out

# View coverage
go tool cover -html=coverage.out
```

**Documentation**:
- All exported functions have godoc comments
- Complex logic has inline comments
- Examples in tests

### Git Workflow

**Branches**:
- `main` - stable, releases
- `develop` - active development
- `feature/*` - feature branches
- `fix/*` - bug fixes

**Commits**:
Follow [Conventional Commits](https://conventionalcommits.org/):
```
feat: add Anthropic provider support
fix: cache key collision on similar prompts
docs: add configuration guide
test: add generator unit tests
```

### Testing Strategy

**Unit tests** (fast, isolated):
```go
func TestCacheKey(t *testing.T) {
    key1 := cache.Key("prompt", "model")
    key2 := cache.Key("prompt", "model")
    assert.Equal(t, key1, key2)  // Deterministic
}
```

**Integration tests** (slower, real dependencies):
```go
func TestGenerateWithOpenAI(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    // Real OpenAI API call
}
```

**Table-driven tests**:
```go
func TestParseModel(t *testing.T) {
    tests := []struct {
        input    string
        provider string
        model    string
    }{
        {"openai:gpt-4", "openai", "gpt-4"},
        {"anthropic", "anthropic", ""},
        {"ollama:llama3.3", "ollama", "llama3.3"},
    }
    for _, tt := range tests {
        t.Run(tt.input, func(t *testing.T) {
            p, m := parseModel(tt.input)
            assert.Equal(t, tt.provider, p)
            assert.Equal(t, tt.model, m)
        })
    }
}
```

---

## Quick Reference

### Daily Routine

```bash
# Start of day
git pull
go mod tidy
make test

# During development
# 1. Write failing test
# 2. Implement feature
# 3. Make test pass
# 4. Refactor
# 5. Commit

# End of day
go fmt ./...
go vet ./...
make test
git push
```

### Useful Commands

```bash
# Build
make build

# Test
make test

# Run locally
go run cmd/spec/main.go generate "test"

# Install locally
go install ./cmd/spec

# Clean
make clean

# Release
make release VERSION=v1.0.0
```

---

## Success Criteria

### Functional Requirements

- ✅ Generates task specs
- ✅ Generates system designs
- ✅ Generates implementation plans
- ✅ Supports 4+ LLM providers
- ✅ Caching works (mem + disk)
- ✅ Transform operations work
- ✅ Validation works
- ✅ Works offline (with cache/templates)

### Non-Functional Requirements

- ✅ Startup time <5ms
- ✅ Binary size <15MB
- ✅ Test coverage >80%
- ✅ No critical bugs
- ✅ Works on Linux, macOS, Windows
- ✅ Clear documentation
- ✅ Easy installation

### User Experience

- ✅ Intuitive CLI (no docs needed for basic use)
- ✅ Helpful error messages
- ✅ Fast responses (with cache)
- ✅ Composable with other tools

---

## Risk Management

### Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| LLM API changes | High | Version API calls, graceful degradation |
| Cache corruption | Medium | Validate cache entries, easy clear |
| Large binary size | Low | Strip debug info, UPX compression |
| Cross-platform issues | Medium | Test on all platforms, CI matrix |
| Performance bottlenecks | Low | Profile early, optimize hot paths |

---

## Post-v1.0 Roadmap

**v1.1**: Plugin system
**v1.2**: Daemon mode (Unix socket server)
**v1.3**: Web UI (optional)
**v1.4**: MCP server support
**v2.0**: Advanced features (batch, search integration, etc.)

---

**Let's build this! 🚀**
