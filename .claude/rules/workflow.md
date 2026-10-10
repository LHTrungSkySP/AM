# Workflow

- Run all commands from the repo root, where `AgentManage.slnx` lives.
- Non-trivial features get a plan file under `plans/` before implementation — check
  `plans/README.md` for the expected shape, and check `plans/` for existing context
  before starting work on a feature.
- Plans are broken into task files under `plans/tasks/` from `plans/tasks/_TEMPLATE.md`.
  Every agent working a task keeps its header (status, progress, agent log, new tech)
  current — see `.claude/rules/task-tracking.md`. This is how the human follows the work.
- Dispatch to the specialized subagent that matches the task instead of doing
  everything as the general-purpose agent:
  - **business-analyst** — research/clarify business requirements, write them up as a
    plan in `plans/` and split it into task files. Does not write code.
  - **researcher** — technical research (library choices, prior art) that informs a plan
    or implementation decision. Read-only.
  - **coder** — implements features/fixes across Domain/Application/Infrastructure/WebAPI.
  - **tester** — writes and runs unit/integration tests.
  - **reviewer** — reviews diffs for correctness and layering violations. Read-only on
    code; may only write its log entry into the task file.
  - **architect-doc** — syncs `.claude/rules/` and `CLAUDE.md` with the code.
- Before committing: `dotnet build` must succeed and `dotnet test` must pass (once
  test projects exist).
- Only create git commits when the user explicitly asks for one. Never `--force` push
  or skip hooks (`--no-verify`) without explicit instruction.
- Keep changes scoped to the layer the task actually touches — don't opportunistically
  refactor unrelated code in the same commit.
