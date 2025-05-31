# SpecForge – Next-Generation Task & Design Spec Assistant

This document re-imagines **TaskSpec** from the ground up with a sharper focus on *user experience* and *agent interoperability*.  
All names, commands, flags, and flows have been redesigned for clarity and discoverability, while preserving the core power of the original tool.

---

## 1. Guiding Principles

| # | Principle | Rationale |
|---|-----------|-----------|
| 1 | *Human-Centric CLI* | Commands should read like sentences; defaults should “do the right thing.” |
| 2 | *Progressive Disclosure* | Casual users get sensible defaults; power users can drill down with advanced flags. |
| 3 | *Convention over Configuration* | Fewer required flags; rely on sane conventions and project metadata. |
| 4 | *Stateless by Default* | Outputs are predictable; side-effects (cache, env) are opt-in & visible. |
| 5 | *First-class Agent API* | Every CLI feature is one RPC away for AI agents via an MCP server wrapper. |

---

## 2. New Top-Level Command & Namespace

```
spec <verb> [subject] [options]
```

* `spec` is short, memorable, and directly implies *specifications*.
* Verbs are **imperative** and map 1-to-1 with user goals.

### 2.1 Verb Matrix (Old → New)

| Old TaskSpec | New SpecForge | Notes |
|--------------|--------------|-------|
| `analyze`    | `spec task`   | “Plan this task.” |
| `design`     | `spec system` | broader scope system design |
| `split`      | *(flag `--slice`)* | handled via --slice on system |

### 2.2  Help Layout

```
spec --help           # overview + verb list
spec <verb> --help    # deep-dive per verb
```

---

## 3. Command Specs

### 3.1 `spec task`

Analyze **any** task description and return an actionable plan.

```
spec task <task-text | ->                 # read from arg or stdin
          [--from <file>]                 # explicit file input
          [--to   <file|dir>]             # write result (auto-name if dir)
          [--model <provider:model>]      # e.g. openai:gpt-4o or ollama:llama3
          [--search]                      # augment with web context
          [--template <file>]             # custom Jinja/MD template
          [--no-validate]                 # skip sanity pass
          [-q|--quiet]                    # suppress stdout
          [-v|--verbose]
```

* **Data Flow**  
  `stdin/arg → validation → (cache?) → LLM → template → output`
* **Defaults**  
  `--to` omitted ⇒ `specs/<slug>_<timestamp>.md`  
  `--model` omitted ⇒ fallback chain *config → env → builtin default*.

#### Pros & Cons of Function-level Validation
| Approach | Pros | Cons |
|----------|------|------|
| On by default (current) | catches bad prompts early | extra latency/cost |
| Off by default | fastest path | user may get poor spec |
| Toggle via `--validate` (chosen) | flexible, discoverable | slightly longer flag list |

### 3.2 `spec system`

Create or refine a **system design**.

```
spec system [--from <file>]               # existing design doc
            [--interactive]               # guided interview
            [--format md|json|yaml]       # output
            [--conventions <file>]        # team style guide
            [--deep-task]                 # run spec plan on every subtask
            [common LLM/cache flags]
```

*Interactive flow* ends with a **Yes/No** prompt: *“Extract phases now?”*

#### Output Naming
* If `--from` given → derives slug from file name.  
* If `--interactive` → slug = `system_design`.

### 3.3 `spec plan`

Convert an **existing system design** into a sequenced implementation plan (tasks & phases) *without* altering the original design content.

```
spec plan --from <design.md>                # required design doc
          [--to <file|dir>]                 # write tasks (one file or dir)
          [--model <provider:model>]        # optional LLM override
          [--format md|json|yaml]           # output structure
          [--slice] [--dir <outDir>]        # additionally slice phases files
          [-q|--quiet] [-v]
```

*Essentially what `--deep-task` used to do, but as a first-class verb.*

#### Pros vs. `--deep-task` Flag
| Approach | Pros | Cons |
|----------|------|------|
| Dedicated `plan` verb (chosen) | Clear separation, reusable independently | Adds third verb |
| Keep only `--deep-task` | Fewer verbs | Hidden capability, longer command |

---

## 4. Global Flags & Behaviour

```
--cache [mem|disk]          # enable + backend
--cache-ttl <sec>
--clear-cache
--output-dir <dir>          # overrides .env default
--quiet / --verbose
```

These may be placed **before or after** the verb (parsed by root cmd).

---

## 5. UX Improvements Over TaskSpec

| Area | TaskSpec | SpecForge Improvement |
|------|----------|-----------------------|
| Naming | `analyze`, `design`, `split` | `task`, `system`, `plan` verbs |
| Input | mixed positional/flags | Consistent `--from` / stdin / arg pattern |
| Output | auto files in various dirs | Single configurable `--output-dir` + `--to` override |
| Validation | on by default | explicit `--no-validate` toggle |
| Quiet mode | `--no-stdout` | `--quiet` (common Unix convention) |
| Model choose | `--provider` + `--model` | Single `--model provider:name` string |
| Help | long | verb-centric concise help with examples |

---

## 6. MCP Server Wrapper

### 6.1 Goals
* Expose every CLI capability to AI agents (Cascade, LangChain, etc.).
* Stateless, idempotent operations; no hidden global CWD assumptions.
* Streaming responses when possible for progress updates.

### 6.2 API Surface (Option A – Thin Wrapper)

| Endpoint | Description |
|----------|-------------|
| `task`   | Mirrors `spec task` flags. |
| `system` | Mirrors `spec system`.     |
| `plan`   | Mirrors `spec plan`.       |
| `status` | Return job progress (for async). |

*Pros*: 1-1 mapping, easiest to reason about.  
*Cons*: API churn if CLI changes; some duplication.

### 6.3 API Surface (Option B – Generic Exec)

Single endpoint `exec` with payload:
```json
{
  "command": "plan",
  "args":   "Generate a blog engine",
  "options": {
     "model": "openai:gpt-4o",
     "search": true
  }
}
```
*Pros*: Future-proof; fewer endpoints.  
*Cons*: Client must know CLI schema; harder to type-check.

### 6.4 Recommendation
Implement **Option A** initially (clarity > flexibility).  Provide `exec` as *beta* for advanced agents.

### 6.5 Streaming vs Blocking
* **Approach 1 – WebSocket / Server-sent-events**  
  *Pros*: real-time updates, lower latency.  
  *Cons*: more infra complexity.
* **Approach 2 – Polling `status`** *(chosen MVP)*  
  *Pros*: simple HTTP; works everywhere.  
  *Cons*: less immediate.

---

## 7. Future Nice-to-Haves
* **`spec review`** – LLM critique of existing spec files.
* **GUI** – Electron/Tauri wrapper with local Ollama support.
* **Plugin System** – Allow org-specific templates & validators.

---

## 8. Summary

SpecForge retains TaskSpec’s core strengths while simplifying day-to-day CLI usage and adding first-class AI-agent interoperability via an MCP server.  Names are shorter, flags are clearer, and advanced flows (validation, deep planning, slicing) are opt-in yet discoverable.
