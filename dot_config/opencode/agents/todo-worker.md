---
description: Receives a task description, implementation plan, and worktree path. Implements the plan, runs tests, commits, and reports success or structured failure.
mode: subagent
hidden: true
model: anthropic/claude-sonnet-4-20250514
permission:
  edit: allow
  question: allow
  bash:
    "*": allow
    "git push*": ask
  task:
    "*": deny
---

{file:~/.config/opencode/prompts/worker.txt}
