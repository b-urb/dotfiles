---
description: Receives a task description, implementation plan, and worktree path. Implements the plan, runs tests, commits, and reports success or structured failure.
mode: subagent
hidden: true
model: openai/gpt-5.5
variant: medium
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
