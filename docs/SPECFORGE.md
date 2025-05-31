# SpecForge – Implementation Roadmap (Elixir Edition)

This document transforms `NEW_DESIGN.md` into a **step-by-step execution plan** for building SpecForge as an Elixir umbrella project.  Each step provides:

* **Shell commands** to run (tested on mac OS).  
* **Suggested AI-agent prompts** you can feed to Cascade (or another agent) so it can automate the boring parts.  
* **Tech-stack notes** with options & pros/cons where appropriate.

---

## 0 · Prerequisites & Toolchain

| Tool | Version | Install Command |
|------|---------|-----------------|
| Elixir | ≥ 1.17 (OTP 27) | `brew install elixir` or `asdf install elixir 1.17.0` |
| Node.js | ≥ 20 (for Phoenix assets) | `brew install node` or `asdf install nodejs 20.11.0` |
| PostgreSQL | *Optional* (if we add persistence) | `brew install postgresql` |
| Mix & Hex | bundled with Elixir | `mix local.hex --force` |

> AI Prompt: *“Verify host has Elixir 1.17, Node 20, and Hex. Install via Homebrew/asdf if missing.”*

---

## 1 · Create the Umbrella Skeleton

```bash
mkdir -p ~/code/specforge
cd ~/code/specforge
mix new . --umbrella
```

Umbrella layout lets us isolate concerns:

* **specforge_core** – shared domain & adapters (LLM, caching, etc.).  
* **specforge_cli**  – Owl-based CLI.  
* **specforge_web**  – Phoenix web & MCP server.

> AI Prompt: *“Inside umbrella, create three apps: specforge_core (sup), specforge_cli (sup), specforge_web (phx.new --no-ecto). Configure mix paths accordingly.”*

---

## 2 · Wire In Local Libraries (`ex_llm`, `ex_mcp`)

Inside each app that needs them (likely **core** & **web**):

```elixir
# apps/specforge_core/mix.exs
  defp deps do
    [
      {:ex_llm, path: "../../ex_llm"},
      {:ex_mcp, path: "../../ex_mcp"},
      {:cachex, "~> 3.6"},      # caching layer
      {:jason, "~> 1.4"}
    ]
  end
```

> AI Prompt: *“Add ex_llm (path), ex_mcp (path) and Cachex to core’s dependencies, run `mix deps.get`, ensure compile passes.”*

---

## 3 · Design Core Behaviour Modules

| Interface | Responsibility |
|-----------|---------------|
| `SpecForge.TaskPlanner` | Implements **spec task** verb: validate → LLM → template → file. |
| `SpecForge.SystemDesigner` | Implements **spec system** verb (interactive & file modes). |
| `SpecForge.PlanGenerator` | Converts existing design into tasks (former deep-task). |
| `SpecForge.Slicer` | Pure text/markdown splitter used internally by system & plan when `--slice`. |

Tech choices:

* **Cache:** Cachex (ETS-backed) vs ETS directly.  
  *Pros* – Cachex offers TTL & ops; *Cons* – small extra dep.  (Chosen: **Cachex**)
* **Prompt templates:** use [Temple](https://hex.pm/packages/temple) vs simple EEx.  Temple offers typed prompts; EEx is simpler.  We’ll start with **EEx** for speed.

> AI Prompt: *“Generate behaviour specs and stub modules in specforge_core for TaskPlanner, SystemDesigner, PlanGenerator, Slicer. Include dialyzer @specs.”*

---

## 4 · Implement CLI with Owl

```bash
cd apps/specforge_cli
mix deps.get
echo '{:owl, "~> 0.7"}' >> mix.exs  # add dep then run mix deps.get
```

CLI entry: `SpecForge.CLI.main/1` → parse args → dispatch to core.

Key Owl helpers:

* `Owl.Prompt.choice/2` – for *Yes/No* extraction prompt.  
* `Owl.Progress` – live LLM progress bar.

> AI Prompt: *“Implement SpecForge.CLI using Owl: subcommands task/system/plan, global flags, help banners, colorised output.”*

---

## 5 · Phoenix Web & MCP Server

```bash
cd ../../
mix phx.new apps/specforge_web --no-ecto --no-dashboard --app specforge_web --module SpecForgeWeb
cd apps/specforge_web
mix deps.get
```

### 5.1 Routing

```
POST /api/task   → TaskController
POST /api/system → SystemController
POST /api/plan   → PlanController
GET  /api/status/:job → StatusController
```

Option: **WebSockets (LiveView or Phoenix Channels)** for streaming; fallback to polling.

| Approach | Pros | Cons |
|----------|------|------|
| Polling  | trivial HTTP; works everywhere | latency, extra requests |
| WebSocket | real-time | more infra config |

MVP→ **Polling**, roadmap→ WebSocket.

> AI Prompt: *“Generate Phoenix controllers calling specforge_core; each request spawns Task.Supervisor async job, returns job_id; implement StatusController querying ETS for progress.”*

---

## 6 · Interactive Flow (CLI & Web)

1. **System design interactive** → Owl prompts OR LiveView wizard.  
2. On completion, ask: *“Slice phases now?”*.  
3. If yes, call `Slicer` and write files under `--dir` or default output dir.
4. Optional step: *“Generate task plan from design?”* → triggers `PlanGenerator`.

> AI Prompt: *“Implement interactive flow in SystemDesigner with Owl streaming, reuse same logic in LiveView component.”*

---

## 7 · Persistence (Optional)

We might want to store job metadata & generated docs.

| Option | Pros | Cons |
|--------|------|------|
| **None (files only)** | simplest; no DB | no dashboards/search |
| **SQLite (Ecto 3.12)** | zero-config, light | concurrent writers require care |
| **PostgreSQL** | robust; horiz. growth | extra setup |

MVP ⇒ **No DB** (just filesystem).  Future toggle via config.

---

## 8 · Testing & QA

| Layer | Tooling |
|-------|---------|
| Unit  | ExUnit + Mox (mock ex_llm) |
| Property | StreamData for prompt parsing |
| Smoke | `mix escript.build` + CLI commands in CI |
| Web API | ExUnit + Phoenix.ConnTest |

> AI Prompt: *“Write ExUnit tests for TaskPlanner happy path using Mox stub of ex_llm response.”*

---

## 9 · CI & Release

* **GitHub Actions**: matrix `(otp, elixir)` + Node build cache.  
* **Brick** or **Mix Release** for CLI binary & Docker image.

> AI Prompt: *“Author `.github/workflows/ci.yml` for Elixir 1.17; run `mix test` and build release artifact.”*

---

## 10 · Developer-Setup Script

Create `bin/setup`:

```bash
#!/usr/bin/env bash
asdf install                 # if using asdf
mix deps.get --all
cd apps/specforge_web && npm install && npm run deploy
```

> AI Prompt: *“Generate bin/setup that checks Elixir/Node versions, installs deps, creates env files.”*

---

## 11 · Future Enhancements (from NEW_DESIGN.md §7)

* **`spec review`** verb.  
* **GUI (Tauri/Electron)** consuming `/api`.  
* **Plugin system** via Elixir behaviours & `mix specforge.gen.plugin`.

---

## 12 · Timeline Snapshot

| Week | Milestone |
|------|-----------|
| 1 | Umbrella, deps, basic CLI `task` happy path |
| 2 | `system` interactive + `--slice` |
| 3 | `plan` verb + Cachex + tests |
| 4 | Phoenix API + minor web UI |
| 5 | MCP polish, CI & Release |

Adjust as resources permit.

---

## 13 · Quick-Start (Once Implemented)

```bash
# CLI
mix escript.build -o spec
./spec task "Implement user authentication"

# Web (dev)
cd apps/specforge_web
mix phx.server  # then open http://localhost:4000
```

---

**You’re all set.** Follow each numbered section, feed the suggested prompts to your AI agent, and SpecForge will be up and running with a robust Elixir foundation, Owl-powered CLI, Phoenix web/MCP layer, and LLM super-powers courtesy of `ex_llm`.
