# TASKS

This file tracks pending, in-progress, and completed tasks for the SpecForge umbrella implementation.
Check a box once the task is finished. Add notes or issues below the task list.

## Pending

- [ ] Create Phoenix API controllers (TaskController, SystemController, PlanController, StatusController)
- [ ] Implement interactive flow for system design
- [ ] Create developer setup script (bin/setup)
- [ ] Set up ExUnit test structure
- [ ] Configure GitHub Actions CI/CD

## Completed

- [x] Create `specforge_core` umbrella child application (`mix new apps/specforge_core --sup`)
- [x] Create `specforge_cli` umbrella child application (`mix new apps/specforge_cli --sup`)
- [x] Create `specforge_web` Phoenix child application (`mix phx.new apps/specforge_web --no-ecto --no-dashboard --app specforge_web --module SpecForgeWeb`)
- [x] Wire in local libraries (ex_llm, ex_mcp) to specforge_core
- [x] Add Cachex dependency to specforge_core
- [x] Design core behaviour modules (TaskPlanner, SystemDesigner, PlanGenerator, Slicer)
- [x] Add Owl dependency to specforge_cli
- [x] Create CHANGELOG.md following Keep a Changelog format
- [x] Add Credo for code linting
- [x] Add Dialyxir for static type checking
- [x] Add Sobelow for security scanning
- [x] Create stub implementations for core modules (TaskPlanner, SystemDesigner, PlanGenerator, Slicer)
- [x] Implement CLI entry point with Owl (spec task, system, plan commands)

## Notes / Issues

- Phoenix generation initially failed due to existing file conflict, manually resolved by user
- Need to verify ex_llm and ex_mcp libraries exist in parent directory before wiring them in

- Phoenix generation failed due to existing file at `assets/vendor/heroicons/optimized`.
  Review and delete the conflicting file (or remove `specforge_web` directory) before rerunning `mix phx.new`.
- Ensure Phoenix archive is installed before generating `specforge_web`.
