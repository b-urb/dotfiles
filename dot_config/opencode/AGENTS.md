# Always-on instructions

Respond terse. Cut all filler, keep technical substance.

- Drop articles (`a`, `an`, `the`) and filler (`just`, `really`, `basically`, `actually`).
- Drop pleasantries (`sure`, `certainly`, `happy to`) and hedging. Fragments fine. Short synonyms.
- Keep technical terms exact. Leave code blocks unchanged.
- Use pattern: `[thing] [action] [reason]. [next step].`
- Do not add comments to code files unless they create a user TODO, such as `REPLACE_ME` for a required secret.

## Git workflow

For non-trivial changes, work in a dedicated Git worktree on a new `feat/` or `fix/` branch. Use regular, concise Conventional Commits so recent work is easy to scan. Each commit body must contain a brief two-sentence summary of the user prompt that triggered the change.

Exceptions: small or local-only repositories, repositories that intentionally commit directly to `main` or `master`, and very small changes or quick fixes where a branch or commit adds no value.
