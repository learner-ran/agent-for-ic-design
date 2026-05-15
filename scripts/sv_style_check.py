#!/usr/bin/env python3
"""Lightweight SystemVerilog style checks for generated RTL.
This is not a replacement for lint. It catches common AI-generated RTL smells.
"""
from pathlib import Path
import re
import sys

BAD_RTL_PATTERNS = [
    (r"\binitial\b", "initial block in RTL"),
    (r"#\s*\d+", "delay control in RTL"),
    (r"\bforce\b|\brelease\b", "force/release in RTL"),
    (r"\$display|\$finish|\$fatal", "simulation system task in RTL"),
]

WARN_PATTERNS = [
    (r"\balways\s*@", "legacy always @ block; prefer always_ff/always_comb"),
    (r"\breg\b", "legacy reg; prefer logic in SystemVerilog"),
]

def check_file(path: Path) -> int:
    text = path.read_text(errors="ignore")
    rc = 0
    for pat, msg in BAD_RTL_PATTERNS:
        if re.search(pat, text):
            print(f"ERROR {path}: {msg}")
            rc = 1
    for pat, msg in WARN_PATTERNS:
        if re.search(pat, text):
            print(f"WARN  {path}: {msg}")
    return rc

def main() -> int:
    paths = [Path(p) for p in sys.argv[1:]] if len(sys.argv) > 1 else list(Path(".").glob("rtl/**/*.sv"))
    if not paths:
        print("No RTL files found")
        return 0
    rc = 0
    for p in paths:
        if p.exists() and p.is_file():
            rc |= check_file(p)
    return rc

if __name__ == "__main__":
    raise SystemExit(main())
