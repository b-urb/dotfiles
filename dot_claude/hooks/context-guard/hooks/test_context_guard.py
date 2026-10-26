import json
import os
import subprocess
import sys
import tempfile
import uuid

HOOK = os.path.join(os.path.dirname(__file__), "context_guard.py")


def run(lines, limit, event="PostToolUse", sid=None):
    with tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False) as f:
        f.write("\n".join(json.dumps(x) for x in lines))
    payload = {"hook_event_name": event, "transcript_path": f.name, "session_id": sid or uuid.uuid4().hex}
    out = subprocess.run([sys.executable, HOOK], input=json.dumps(payload), capture_output=True, text=True,
                         env={**os.environ, "HL_WRAPUP_TOKENS": str(limit)}, check=True).stdout
    return json.loads(out)["hookSpecificOutput"]["additionalContext"] if out.strip() else None


claude = [{"message": {"usage": {"input_tokens": 10, "cache_read_input_tokens": 200000, "cache_creation_input_tokens": 5000}}}]
codex = [{"type": "event_msg", "payload": {"type": "token_count", "info": {
    "last_token_usage": {"input_tokens": 210000}, "model_context_window": 200000}}}]

assert run(claude, 300000) is None
assert "205,010 tokens" in run(claude, 200000)
assert "threshold 170,000" in run(codex, 300000)
sid = uuid.uuid4().hex
assert run(claude, 200000, sid=sid) and run(claude, 200000, sid=sid) is None
assert "compacted" in run([], 1, event="SessionStart")
print("ok")
