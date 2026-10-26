#!/usr/bin/env python3
import json
import os
import sys
import tempfile

LIMIT = int(os.environ.get("HL_WRAPUP_TOKENS", "300000"))
STEP = 25000
MESSAGE = ("Context guard: {why}. Finish the current step, commit and push, then, if you hold a Vikunja task, "
           "release it with --status handoff and a self-contained handoff note (homelab-work skill) and stop. "
           "Without a task, tell BU to continue in a fresh session.")


def used_tokens(path):
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 512 * 1024))
            lines = f.read().decode(errors="replace").splitlines()
    except OSError:
        return 0, 0
    for line in reversed(lines):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        usage = (d.get("message") or {}).get("usage") if isinstance(d.get("message"), dict) else None
        if usage:
            return (usage.get("input_tokens", 0) + usage.get("cache_read_input_tokens", 0)
                    + usage.get("cache_creation_input_tokens", 0)), 0
        info = (d.get("payload") or {}).get("info") if isinstance(d.get("payload"), dict) else None
        if info and info.get("last_token_usage"):
            return info["last_token_usage"].get("input_tokens", 0), info.get("model_context_window") or 0
    return 0, 0


def emit(event, why):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": MESSAGE.format(why=why)}}))


def main():
    data = json.load(sys.stdin)
    event = data.get("hook_event_name", "PostToolUse")
    if event == "SessionStart":
        emit(event, "the context was just compacted, earlier detail is lost")
        return
    used, window = used_tokens(data.get("transcript_path") or "")
    limit = min(LIMIT, int(window * 0.85)) if window else LIMIT
    if used < limit:
        return
    state = os.path.join(tempfile.gettempdir(), f"context-guard-{data.get('session_id', 'x')}")
    try:
        last = int(open(state).read())
    except (OSError, ValueError):
        last = 0
    if used - last < STEP:
        return
    open(state, "w").write(str(used))
    emit(event, f"{used:,} tokens in context, wrap-up threshold {limit:,}")


if __name__ == "__main__":
    main()
