#!/usr/bin/env python3
"""Sync installed packages back into dotfiles package lists.

Inspects the current system for installed packages and updates the
dotfiles repo manifests to match. Default mode is dry-run (show diff);
pass --apply to write changes or --check to fail on drift.
"""

from __future__ import annotations

import argparse
import difflib
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Match, Optional

# ─── Constants ───────────────────────────────────────────────────────────────

DOTFILES_DIR = Path(__file__).resolve().parent.parent

RED = "\033[31m"
GREEN = "\033[32m"
CYAN = "\033[36m"
BOLD = "\033[1m"
RESET = "\033[0m"

SECTIONS_BY_OS: dict[str, list[str]] = {
    "macos": ["brew", "mas", "vscode", "cargo"],
    "ubuntu": ["apt", "vscode", "cargo"],
    "wsl": ["apt", "vscode", "cargo"],
    "arch": ["pacman", "vscode", "cargo"],
    "windows": ["scoop", "winget", "vscode", "cargo"],
}


# ─── Data types ──────────────────────────────────────────────────────────────

@dataclass
class FileEdit:
    """A pending file modification."""

    path: Path
    old_text: str
    new_text: str


@dataclass
class SectionResult:
    """Result for one sync section."""

    name: str
    added: int = 0
    removed: int = 0
    total: int = 0
    edits: list[FileEdit] = field(default_factory=list)
    report: str = ""

    @property
    def changed(self) -> bool:
        return bool(self.added or self.removed or
                     any(e.old_text != e.new_text for e in self.edits))


# ─── OS detection ────────────────────────────────────────────────────────────

def _is_wsl() -> bool:
    if platform.system() != "Linux":
        return False
    try:
        return "microsoft" in Path("/proc/version").read_text().lower()
    except OSError:
        return False


def detect_os() -> str:
    """Return one of: macos, windows, wsl, arch, ubuntu, unknown."""

    sys_name = platform.system()
    if sys_name == "Darwin":
        return "macos"
    if sys_name == "Windows":
        return "windows"
    if _is_wsl():
        return "wsl"
    if sys_name == "Linux" and shutil.which("pacman"):
        return "arch"
    if sys_name == "Linux" and shutil.which("apt"):
        return "ubuntu"
    return "unknown"


# ─── Shell helpers ───────────────────────────────────────────────────────────

def run_cmd(cmd: list[str]) -> Optional[subprocess.CompletedProcess[str]]:
    """Run a command, return result or None if binary not found."""

    try:
        return subprocess.run(cmd, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        return None


def run_lines(cmd: list[str]) -> Optional[list[str]]:
    """Run a command and return sorted non-empty output lines, or None."""

    proc = run_cmd(cmd)
    if not proc or proc.returncode != 0:
        return None
    return sorted({line.strip() for line in proc.stdout.splitlines() if line.strip()})


# ─── Package list readers ────────────────────────────────────────────────────

def list_brew_taps() -> Optional[list[str]]:
    if not shutil.which("brew"):
        return None
    return run_lines(["brew", "tap"])


def list_brew_formulae() -> Optional[list[str]]:
    """Use `brew leaves` to get only explicitly-installed formulae (not deps)."""

    if not shutil.which("brew"):
        return None
    return run_lines(["brew", "leaves"])


def list_brew_casks() -> Optional[list[str]]:
    if not shutil.which("brew"):
        return None
    return run_lines(["brew", "list", "--cask", "-1"])


def list_mas_apps() -> Optional[list[dict]]:
    """Return list of {id, name} dicts from `mas list`, sorted by name."""

    if not shutil.which("mas"):
        return None
    proc = run_cmd(["mas", "list"])
    if not proc or proc.returncode != 0:
        return None
    apps: list[dict] = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        # Format: <id>  <name>  (<version>)
        m = re.match(r"^(\d+)\s+(.+?)\s*\(\d[^)]*\)\s*$", line)
        if m:
            apps.append({"id": int(m.group(1)), "name": m.group(2).strip()})
    return sorted(apps, key=lambda x: x["name"].lower()) if apps else None


def list_code_extensions() -> Optional[list[str]]:
    """Return installed VS Code extension IDs, sorted lowercase."""

    for code_path in (shutil.which("code"), "/opt/homebrew/bin/code"):
        if not code_path:
            continue
        if not Path(code_path).exists():
            continue
        proc = run_cmd([code_path, "--list-extensions"])
        if proc and proc.returncode == 0:
            # Extension IDs are case-insensitive; normalize to lowercase
            return sorted(
                {line.strip().lower() for line in proc.stdout.splitlines() if line.strip()}
            )
    return None


def list_cargo_crates() -> Optional[list[str]]:
    """Return names of top-level cargo-installed crates."""

    proc = run_cmd(["cargo", "install", "--list"])
    if not proc or proc.returncode != 0:
        return None
    crates: list[str] = []
    for line in proc.stdout.splitlines():
        if not line or line.startswith(" "):
            continue
        m = re.match(r"^([A-Za-z0-9_.-]+)\s+v", line)
        if m:
            crates.append(m.group(1))
    return sorted(set(crates))


def list_scoop_packages() -> Optional[list[str]]:
    """Return scoop package names."""

    if not shutil.which("scoop"):
        return None
    # Try parsing as text; scoop list outputs table lines
    proc = run_cmd(["scoop", "list"])
    if not proc or proc.returncode != 0:
        return None
    pkgs: list[str] = []
    in_body = False
    for line in proc.stdout.splitlines():
        stripped = line.strip()
        if stripped.startswith("----"):
            in_body = True
            continue
        if in_body and stripped:
            parts = stripped.split()
            if parts:
                pkgs.append(parts[0])
    return sorted(set(pkgs)) if pkgs else None


def list_scoop_buckets() -> Optional[list[str]]:
    if not shutil.which("scoop"):
        return None
    proc = run_cmd(["scoop", "bucket", "list"])
    if not proc or proc.returncode != 0:
        return None
    buckets: list[str] = []
    in_body = False
    for line in proc.stdout.splitlines():
        stripped = line.strip()
        if stripped.startswith("----"):
            in_body = True
            continue
        if in_body and stripped:
            buckets.append(stripped.split()[0])
    return sorted(set(buckets)) if buckets else None


def list_winget_packages() -> Optional[list[str]]:
    """Return winget package IDs (fixed-width column parsing)."""

    if not shutil.which("winget"):
        return None
    proc = run_cmd(["winget", "list", "--source", "winget", "--disable-interactivity"])
    if not proc or proc.returncode != 0:
        return None
    # Find the header separator line (dashes) to determine column positions
    lines = proc.stdout.splitlines()
    sep_idx = -1
    for i, line in enumerate(lines):
        if re.match(r"^-+\s+-+", line):
            sep_idx = i
            break
    if sep_idx < 1:
        return None
    # Parse column widths from separator
    header = lines[sep_idx - 1]
    sep = lines[sep_idx]
    # Find the "Id" column
    id_start = header.find("Id")
    if id_start == -1:
        return None
    # Find the end of the Id column by looking at the separator dashes
    dash_groups = list(re.finditer(r"-+", sep))
    id_col_end = len(sep)
    for g in dash_groups:
        if g.start() <= id_start < g.end():
            id_col_end = g.end()
            break
    # Find start of next column
    next_col_start = id_col_end
    for g in dash_groups:
        if g.start() > id_col_end:
            next_col_start = g.start()
            break

    pkgs: list[str] = []
    for line in lines[sep_idx + 1 :]:
        if not line.strip():
            continue
        pkg_id = line[id_start:next_col_start].strip()
        if pkg_id and "." in pkg_id:
            pkgs.append(pkg_id)
    return sorted(set(pkgs))


# ─── File text manipulation ──────────────────────────────────────────────────

def _parse_toml_array(text: str, key: str) -> Optional[tuple[list[str], Match[str]]]:
    """Find a TOML array of strings by key name. Returns (items, match)."""

    # Match:  <optional indent> key = [\n ...\n <optional indent> ]
    pat = re.compile(
        rf"^(\s*{re.escape(key)}\s*=\s*\[)\n(.*?\n)(\s*\])",
        re.MULTILINE | re.DOTALL,
    )
    m = pat.search(text)
    if not m:
        return None
    body = m.group(2)
    items = re.findall(r'"([^"]+)"', body)
    return items, m


def _replace_toml_array(text: str, key: str, items: list[str]) -> str:
    """Replace a TOML array in-place, preserving surrounding indent."""

    parsed = _parse_toml_array(text, key)
    if not parsed:
        return text
    old_items, m = parsed
    # Detect indent from the key line
    key_line = m.group(1)
    indent = re.match(r"^(\s*)", key_line).group(1)  # type: ignore[union-attr]
    item_indent = indent + "    "
    body = "\n".join(f'{item_indent}"{item}",' for item in items)
    replacement = f"{indent}{key} = [\n{body}\n{indent}]"
    return text[: m.start()] + replacement + text[m.end() :]


def _parse_yaml_list(text: str, key: str) -> Optional[tuple[list[str], int, int, str]]:
    """Find a YAML block list by key. Returns (items, start, end, header_line).

    The matched region spans from the key line to the last list/comment line.
    """

    pat = re.compile(
        rf"^(\s*{re.escape(key)}:\s*\n)((?:[ \t]+[#-].*\n)*)",
        re.MULTILINE,
    )
    m = pat.search(text)
    if not m:
        return None
    header = m.group(1)
    body = m.group(2)
    items: list[str] = []
    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            items.append(stripped[2:])
        elif stripped == "-":
            items.append("")
    return items, m.start(), m.end(), header


def _replace_yaml_list(text: str, key: str, items: list[str]) -> str:
    """Replace a YAML block list, dropping any inline comments."""

    parsed = _parse_yaml_list(text, key)
    if not parsed:
        return text
    _, start, end, header = parsed
    body = "\n".join(f"  - {item}" for item in items) + "\n"
    return text[:start] + header + body + text[end:]


def _parse_yaml_mas_list(text: str) -> Optional[tuple[list[dict], int, int]]:
    """Parse mas_apps YAML block. Returns (items, start, end)."""

    # Non-empty: mas_apps:\n  - { id: N, name: "..." }\n...
    pat = re.compile(
        r"^(mas_apps:\s*\n)((?:  - \{ id: \d+, name: \"[^\"]*\" \}\n)*)",
        re.MULTILINE,
    )
    m = pat.search(text)
    if m:
        body = m.group(2)
        items: list[dict] = []
        for em in re.finditer(r'\{ id: (\d+), name: "([^"]+)" \}', body):
            items.append({"id": int(em.group(1)), "name": em.group(2)})
        return items, m.start(), m.end()
    # Empty: mas_apps: []
    pat_empty = re.compile(r"^mas_apps:\s*\[\]\s*\n?", re.MULTILINE)
    me = pat_empty.search(text)
    if me:
        return [], me.start(), me.end()
    return None


def _replace_yaml_mas_list(text: str, items: list[dict]) -> str:
    """Replace mas_apps block with sorted items."""

    parsed = _parse_yaml_mas_list(text)
    if parsed is None:
        return text
    _, start, end = parsed
    if items:
        sorted_items = sorted(items, key=lambda x: x["name"].lower())
        body = "\n".join(
            f'  - {{ id: {item["id"]}, name: "{item["name"]}" }}'
            for item in sorted_items
        ) + "\n"
        replacement = f"mas_apps:\n{body}"
    else:
        replacement = "mas_apps: []\n"
    return text[:start] + replacement + text[end:]


# ─── Sync logic per section ──────────────────────────────────────────────────

def _diff_lists(old: list[str], new: list[str]) -> tuple[int, int]:
    """Return (added_count, removed_count)."""

    old_set, new_set = set(old), set(new)
    return len(new_set - old_set), len(old_set - new_set)


def sync_brew(results: list[SectionResult]) -> None:
    """Sync brew taps, formulae, casks against macos Ansible vars."""

    path = DOTFILES_DIR / "ansible" / "roles" / "macos" / "vars" / "main.yml"
    text = path.read_text() if path.exists() else None
    if text is None:
        results.append(SectionResult("brew", report=f"Missing: {path}"))
        return

    original = text
    sub_results: list[SectionResult] = []

    for key, fetcher in [
        ("brew_taps", list_brew_taps),
        ("brew_formulae", list_brew_formulae),
        ("brew_casks", list_brew_casks),
    ]:
        installed = fetcher()
        if installed is None:
            sub_results.append(SectionResult(key, report="brew not available"))
            continue
        parsed = _parse_yaml_list(text, key)
        if not parsed:
            sub_results.append(SectionResult(key, report=f"Key '{key}' not found in {path.name}"))
            continue
        current_items = parsed[0]
        new_items = sorted(set(installed))
        added, removed = _diff_lists(current_items, new_items)
        text = _replace_yaml_list(text, key, new_items)
        sub_results.append(SectionResult(key, added=added, removed=removed, total=len(new_items)))

    # Attach the single file edit to each sub-result that has changes,
    # but only create one FileEdit (deduplication happens in main via path key)
    if text != original:
        edit = FileEdit(path, original, text)
        # Attach to the first sub-result so the diff gets printed once
        for sr in sub_results:
            if sr.added or sr.removed:
                sr.edits.append(edit)
                break

    results.extend(sub_results)


def sync_mas(results: list[SectionResult]) -> None:
    """Sync Mac App Store apps to ansible/roles/macos/vars/main.yml."""

    path = DOTFILES_DIR / "ansible" / "roles" / "macos" / "vars" / "main.yml"
    if not path.exists():
        results.append(SectionResult("mas_apps", report=f"Missing: {path}"))
        return

    text = path.read_text()
    parsed = _parse_yaml_mas_list(text)
    if parsed is None:
        results.append(SectionResult("mas_apps", report="Key 'mas_apps' not found"))
        return

    current_items, _, _ = parsed
    installed = list_mas_apps()
    if installed is None:
        results.append(SectionResult(
            "mas_apps",
            report="mas not available — install via brew or sign in to App Store",
        ))
        return

    current_ids = {item["id"] for item in current_items}
    installed_ids = {item["id"] for item in installed}
    added = len(installed_ids - current_ids)
    removed = len(current_ids - installed_ids)
    new_text = _replace_yaml_mas_list(text, installed)
    results.append(SectionResult(
        "mas_apps",
        added=added, removed=removed, total=len(installed),
        edits=[FileEdit(path, text, new_text)] if new_text != text else [],
    ))


def sync_vscode(results: list[SectionResult]) -> None:
    """Sync VS Code extensions to .chezmoidata.toml and ansible/group_vars/all.yml."""

    exts = list_code_extensions()
    if exts is None:
        results.append(SectionResult("vscode_extensions", report="code not available"))
        return

    # 1. .chezmoidata.toml (TOML array)
    toml_path = DOTFILES_DIR / ".chezmoidata.toml"
    if toml_path.exists():
        toml_text = toml_path.read_text()
        parsed = _parse_toml_array(toml_text, "vscode_extensions")
        if parsed:
            current, _ = parsed
            # Normalize current to lowercase for comparison
            current_lower = [x.lower() for x in current]
            new_items = sorted(set(exts))
            added, removed = _diff_lists(current_lower, new_items)
            new_text = _replace_toml_array(toml_text, "vscode_extensions", new_items)
            results.append(SectionResult(
                "vscode (chezmoidata)",
                added=added, removed=removed, total=len(new_items),
                edits=[FileEdit(toml_path, toml_text, new_text)] if new_text != toml_text else [],
            ))
        else:
            results.append(SectionResult("vscode (chezmoidata)", report="Key not found"))

    # 2. ansible/group_vars/all.yml (YAML list)
    yml_path = DOTFILES_DIR / "ansible" / "group_vars" / "all.yml"
    if yml_path.exists():
        yml_text = yml_path.read_text()
        parsed_y = _parse_yaml_list(yml_text, "vscode_extensions")
        if parsed_y:
            current_y = parsed_y[0]
            current_y_lower = [x.lower() for x in current_y]
            new_items = sorted(set(exts))
            added, removed = _diff_lists(current_y_lower, new_items)
            new_text = _replace_yaml_list(yml_text, "vscode_extensions", new_items)
            results.append(SectionResult(
                "vscode (all.yml)",
                added=added, removed=removed, total=len(new_items),
                edits=[FileEdit(yml_path, yml_text, new_text)] if new_text != yml_text else [],
            ))
        else:
            results.append(SectionResult("vscode (all.yml)", report="Key not found"))


def sync_cargo(results: list[SectionResult]) -> None:
    """Sync cargo crates, preserving --locked and other flags."""

    path = DOTFILES_DIR / "ansible" / "group_vars" / "all.yml"
    if not path.exists():
        results.append(SectionResult("cargo_crates", report=f"Missing: {path}"))
        return

    text = path.read_text()
    parsed = _parse_yaml_list(text, "cargo_crates")
    if not parsed:
        results.append(SectionResult("cargo_crates", report="Key not found"))
        return

    current_items = parsed[0]
    # Build map: crate_name -> full entry (with flags)
    flags_map: dict[str, str] = {}
    for entry in current_items:
        name = entry.split()[0]
        flags_map[name] = entry

    installed = list_cargo_crates()
    if installed is None:
        results.append(SectionResult("cargo_crates", report="cargo not available"))
        return

    new_items: list[str] = []
    for crate in sorted(set(installed)):
        if crate in flags_map:
            new_items.append(flags_map[crate])
        else:
            new_items.append(crate)

    added = len(set(installed) - set(flags_map))
    removed = len(set(flags_map) - set(installed))
    new_text = _replace_yaml_list(text, "cargo_crates", new_items)
    results.append(SectionResult(
        "cargo_crates",
        added=added, removed=removed, total=len(new_items),
        edits=[FileEdit(path, text, new_text)] if new_text != text else [],
    ))


def sync_scoop_winget(results: list[SectionResult], section: str) -> None:
    """Sync scoop and/or winget packages in .chezmoidata.toml."""

    toml_path = DOTFILES_DIR / ".chezmoidata.toml"
    if not toml_path.exists():
        results.append(SectionResult(section, report=f"Missing: {toml_path}"))
        return

    text = toml_path.read_text()
    original = text

    if section in ("scoop", "all"):
        for key, fetcher in [
            ("scoop_buckets", list_scoop_buckets),
            ("scoop_packages", list_scoop_packages),
        ]:
            installed = fetcher()
            if installed is None:
                results.append(SectionResult(key, report="scoop not available"))
                continue
            parsed = _parse_toml_array(text, key)
            if not parsed:
                results.append(SectionResult(key, report=f"Key '{key}' not found"))
                continue
            current, _ = parsed
            new_items = sorted(set(installed))
            added, removed = _diff_lists(current, new_items)
            text = _replace_toml_array(text, key, new_items)
            results.append(SectionResult(key, added=added, removed=removed, total=len(new_items)))

    if section in ("winget", "all"):
        installed = list_winget_packages()
        if installed is None:
            results.append(SectionResult("winget_packages", report="winget not available"))
        else:
            parsed = _parse_toml_array(text, "winget_packages")
            if not parsed:
                results.append(SectionResult("winget_packages", report="Key not found"))
            else:
                current, _ = parsed
                new_items = sorted(set(installed))
                added, removed = _diff_lists(current, new_items)
                text = _replace_toml_array(text, "winget_packages", new_items)
                results.append(SectionResult(
                    "winget_packages", added=added, removed=removed, total=len(new_items),
                ))

    if text != original:
        edit = FileEdit(toml_path, original, text)
        # Attach to the first sub-result that has changes
        for r in results:
            if r.name in ("scoop_buckets", "scoop_packages", "winget_packages") and r.changed:
                r.edits.append(edit)
                break


def validate_apt(results: list[SectionResult], os_name: str) -> None:
    """Validate apt packages — report missing, don't rewrite."""

    if os_name == "wsl":
        key, role = "wsl_ubuntu_packages", "wsl_ubuntu"
    else:
        key, role = "ubuntu_packages", "ubuntu"

    path = DOTFILES_DIR / "ansible" / "roles" / role / "vars" / "main.yml"
    if not path.exists():
        results.append(SectionResult(key, report=f"Missing: {path}"))
        return

    text = path.read_text()
    parsed = _parse_yaml_list(text, key)
    if not parsed:
        results.append(SectionResult(key, report=f"Key '{key}' not found"))
        return

    items = parsed[0]
    missing: list[str] = []
    for item in items:
        pkg = item.split()[0]
        proc = run_cmd(["dpkg", "-s", pkg])
        if not proc or proc.returncode != 0:
            missing.append(item)

    if missing:
        report = f"{key}: {len(missing)} of {len(items)} not installed\n"
        report += "\n".join(f"  - {m}" for m in missing)
    else:
        report = f"{key}: all {len(items)} packages installed"

    results.append(SectionResult(key, removed=len(missing), total=len(items), report=report))


def validate_pacman(results: list[SectionResult]) -> None:
    """Validate pacman packages — report missing, don't rewrite."""

    path = DOTFILES_DIR / "ansible" / "roles" / "arch" / "vars" / "main.yml"
    if not path.exists():
        results.append(SectionResult("arch_packages", report=f"Missing: {path}"))
        return

    text = path.read_text()
    for key in ("arch_packages", "aur_packages"):
        parsed = _parse_yaml_list(text, key)
        if not parsed:
            results.append(SectionResult(key, report=f"Key '{key}' not found"))
            continue
        items = parsed[0]
        missing: list[str] = []
        for item in items:
            pkg = item.split()[0]
            proc = run_cmd(["pacman", "-Qi", pkg])
            if not proc or proc.returncode != 0:
                missing.append(item)
        if missing:
            report = f"{key}: {len(missing)} of {len(items)} not installed\n"
            report += "\n".join(f"  - {m}" for m in missing)
        else:
            report = f"{key}: all {len(items)} packages installed"
        results.append(SectionResult(key, removed=len(missing), total=len(items), report=report))


# ─── Output formatting ──────────────────────────────────────────────────────

def color_diff(diff_text: str) -> str:
    """Colorize unified diff output."""

    lines: list[str] = []
    for line in diff_text.splitlines():
        if line.startswith("---") or line.startswith("+++"):
            lines.append(f"{BOLD}{line}{RESET}")
        elif line.startswith("@@"):
            lines.append(f"{CYAN}{line}{RESET}")
        elif line.startswith("+"):
            lines.append(f"{GREEN}{line}{RESET}")
        elif line.startswith("-"):
            lines.append(f"{RED}{line}{RESET}")
        else:
            lines.append(line)
    return "\n".join(lines)


def make_diff(edit: FileEdit) -> str:
    """Generate unified diff for a FileEdit."""

    rel = str(edit.path.relative_to(DOTFILES_DIR))
    return "\n".join(difflib.unified_diff(
        edit.old_text.splitlines(),
        edit.new_text.splitlines(),
        fromfile=f"a/{rel}",
        tofile=f"b/{rel}",
        lineterm="",
    ))


def print_summary(results: list[SectionResult]) -> None:
    """Print a summary table of all sync results."""

    print(f"\n{BOLD}=== Sync Summary ==={RESET}")
    max_name = max((len(r.name) for r in results), default=10)
    for r in results:
        if r.report and not r.total:
            # Report-only entry (info/warning)
            continue
        pad = " " * (max_name - len(r.name) + 1)
        added = f"{GREEN}+{r.added}{RESET}" if r.added else f"+{r.added}"
        removed = f"{RED}-{r.removed}{RESET}" if r.removed else f"-{r.removed}"
        print(f"  {r.name}:{pad}{added}  {removed}  ({r.total} total)")


# ─── Main ────────────────────────────────────────────────────────────────────

def main() -> int:
    """CLI entry point."""

    parser = argparse.ArgumentParser(
        description="Sync installed packages back into dotfiles manifests.",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run", action="store_true",
        help="Show diffs without writing (default)",
    )
    mode.add_argument(
        "--apply", action="store_true",
        help="Write changes to manifest files",
    )
    mode.add_argument(
        "--check", action="store_true",
        help="Show diffs without writing and exit non-zero if drift exists",
    )
    parser.add_argument(
        "--section",
        help="Sync only a specific section (e.g. brew, mas, vscode, cargo, scoop, winget, apt, pacman)",
    )
    args = parser.parse_args()

    os_name = detect_os()
    if os_name == "unknown":
        print("Could not detect OS.", file=sys.stderr)
        return 1

    valid_sections = SECTIONS_BY_OS.get(os_name, [])
    if args.section and args.section not in valid_sections:
        print(
            f"Section '{args.section}' not valid for {os_name}. "
            f"Valid: {', '.join(valid_sections)}",
            file=sys.stderr,
        )
        return 2

    requested = [args.section] if args.section else valid_sections
    results: list[SectionResult] = []

    try:
        if "brew" in requested:
            sync_brew(results)
        if "mas" in requested:
            sync_mas(results)
        if "vscode" in requested:
            sync_vscode(results)
        if "cargo" in requested:
            sync_cargo(results)
        if "scoop" in requested:
            sync_scoop_winget(results, "scoop")
        if "winget" in requested:
            sync_scoop_winget(results, "winget")
        if "apt" in requested:
            validate_apt(results, os_name)
        if "pacman" in requested:
            validate_pacman(results)
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        return 130

    # Collect all file edits (deduplicate by path — keep the last version)
    file_edits: dict[Path, FileEdit] = {}
    for r in results:
        for edit in r.edits:
            if edit.old_text != edit.new_text:
                file_edits[edit.path] = edit

    # Show diffs
    has_changes = False
    for edit in file_edits.values():
        diff = make_diff(edit)
        if diff:
            has_changes = True
            print(color_diff(diff))
            print()

    # Show reports (validation-only sections)
    for r in results:
        if r.report:
            print(r.report)

    # Show sections with no changes
    seen_names = {r.name for r in results if r.changed or r.report}
    for r in results:
        if r.name not in seen_names and not r.name.endswith("(file)"):
            print(f"No changes for {r.name}")
            seen_names.add(r.name)

    # Write or prompt
    if has_changes:
        if args.apply:
            for edit in file_edits.values():
                edit.path.write_text(edit.new_text)
                rel = edit.path.relative_to(DOTFILES_DIR)
                print(f"{GREEN}Updated{RESET} {rel}")
        else:
            if args.check:
                print(f"\n{RED}sync-back drift detected{RESET}")
                print(f"Run {BOLD}just sync-back-apply{RESET} to write changes.")
            else:
                print(f"\n{BOLD}Run with --apply to write changes.{RESET}")

    print_summary(results)
    if args.check and has_changes:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
