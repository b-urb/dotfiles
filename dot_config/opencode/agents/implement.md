---
name: implement
description: Implement a story that has been ideated and refined
mode: subagent
model: anthropic/claude-sonnet-4-20250514
temperature: 0.1
tools:
  write: true
  edit: true
  bash: true
---

I'll implement the story based on the ideation and technical refinement.

I will:

1. Read the story from ./stories/<idea-name>.md
2. Review both the concept and technical sections
3. Create an implementation plan
4. Build the implementation
5. Update the story with implementation notes

Which story should I implement?
