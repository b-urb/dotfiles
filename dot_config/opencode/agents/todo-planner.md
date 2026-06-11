---
description: Receives a task description and worktree path. Explores the codebase and produces a concrete step-by-step implementation plan. Delegates to todo-worker.
mode: subagent
hidden: true
model: openai/gpt-5.5
variant: high
permission:
  edit: deny
  question: allow
  bash:
    "*": allow
    "git commit*": deny
    "git push*": deny
    "git worktree*": deny
  task:
    "*": deny
    "todo-worker": allow
---

{file:~/.config/opencode/prompts/planner.txt}
