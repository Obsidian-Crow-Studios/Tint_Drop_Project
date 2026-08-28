#!/usr/bin/env python3
"""BFS solver for Tint Drop water-tube levels.

Parses LEVELS from godot/scripts/main.gd (bottom → top chips) and proves
each layout is solvable under the same pour rules as main.gd:
capacity 4, pour a top color-run onto empty or the same top color.

Usage:
  python3 tools/solve_levels.py
  python3 tools/solve_levels.py --gd godot/scripts/main.gd --node-cap 400000
"""

from __future__ import annotations

import argparse
import ast
import re
import sys
from collections import deque
from pathlib import Path

CAPACITY = 4
# Matches TubeView.PALETTE (0..5 today). Not a level-count cap.
MAX_COLOR_ID = 5
DEFAULT_NODE_CAP = 400_000


def parse_levels(gd_path: Path) -> list[list[list[int]]]:
    text = gd_path.read_text(encoding="utf-8")
    match = re.search(
        r"const LEVELS:\s*Array\s*=\s*(\[(?:.|\n)*?\n\])",
        text,
    )
    if not match:
        raise SystemExit(f"Could not find LEVELS array in {gd_path}")
    try:
        levels = ast.literal_eval(match.group(1))
    except (SyntaxError, ValueError) as exc:
        raise SystemExit(f"Failed to parse LEVELS: {exc}") from exc
    if not isinstance(levels, list) or not levels:
        raise SystemExit("LEVELS is empty or not a list")
    return levels


def validate_level(level: list, index: int) -> None:
    counts: dict[int, int] = {}
    for tube in level:
        if not isinstance(tube, list):
            raise SystemExit(f"Level {index + 1}: tube is not a list")
        if len(tube) > CAPACITY:
            raise SystemExit(
                f"Level {index + 1}: tube exceeds capacity {CAPACITY}: {tube}"
            )
        for chip in tube:
            if not isinstance(chip, int) or chip < 0 or chip > MAX_COLOR_ID:
                raise SystemExit(
                    f"Level {index + 1}: color {chip!r} must be int 0..{MAX_COLOR_ID}"
                )
            counts[chip] = counts.get(chip, 0) + 1
    for color, n in sorted(counts.items()):
        if n != CAPACITY:
            raise SystemExit(
                f"Level {index + 1}: color {color} appears {n} times, need {CAPACITY}"
            )
    if not any(len(t) == 0 for t in level):
        raise SystemExit(f"Level {index + 1}: needs at least one empty well")


def _tube_complete(tube: tuple[int, ...]) -> bool:
    return len(tube) == CAPACITY and all(c == tube[0] for c in tube)


def is_won(state: tuple[tuple[int, ...], ...]) -> bool:
    for tube in state:
        if not tube:
            continue
        if not _tube_complete(tube):
            return False
    return True


def _pour(
    src: tuple[int, ...], dst: tuple[int, ...]
) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if not src or len(dst) >= CAPACITY:
        return None
    color = src[-1]
    if dst and dst[-1] != color:
        return None
    run = 0
    for chip in reversed(src):
        if chip != color:
            break
        run += 1
    pour_n = min(run, CAPACITY - len(dst))
    if pour_n <= 0:
        return None
    new_src = src[:-pour_n]
    new_dst = dst + (color,) * pour_n
    return new_src, new_dst


def _canonical(state: tuple[tuple[int, ...], ...]) -> tuple[tuple[int, ...], ...]:
    return tuple(sorted(state))


def solve(
    level: list[list[int]], node_cap: int = DEFAULT_NODE_CAP
) -> dict:
    start = tuple(tuple(t) for t in level)
    if is_won(start):
        return {"ok": True, "moves": 0, "nodes": 1, "depth": 0}

    start_key = _canonical(start)
    visited = {start_key}
    queue: deque[tuple[tuple[tuple[int, ...], ...], int]] = deque([(start, 0)])
    nodes = 1

    while queue:
        state, depth = queue.popleft()
        n = len(state)
        for src_i in range(n):
            src = state[src_i]
            if not src or _tube_complete(src):
                continue
            src_mono = all(c == src[0] for c in src)
            for dst_i in range(n):
                if src_i == dst_i:
                    continue
                dst = state[dst_i]
                poured = _pour(src, dst)
                if poured is None:
                    continue
                new_src, new_dst = poured
                # Relocating a monochrome tube into an empty well is a no-op.
                if src_mono and not dst:
                    continue
                nxt_list = list(state)
                nxt_list[src_i] = new_src
                nxt_list[dst_i] = new_dst
                nxt = tuple(nxt_list)
                key = _canonical(nxt)
                if key in visited:
                    continue
                visited.add(key)
                nodes += 1
                if nodes > node_cap:
                    return {
                        "ok": False,
                        "moves": None,
                        "nodes": nodes,
                        "depth": depth,
                        "reason": f"node cap {node_cap}",
                    }
                if is_won(nxt):
                    return {
                        "ok": True,
                        "moves": depth + 1,
                        "nodes": nodes,
                        "depth": depth + 1,
                    }
                queue.append((nxt, depth + 1))

    return {
        "ok": False,
        "moves": None,
        "nodes": nodes,
        "depth": None,
        "reason": "exhausted",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Prove Tint Drop LEVELS solvable")
    parser.add_argument(
        "--gd",
        type=Path,
        default=Path("godot/scripts/main.gd"),
        help="path to main.gd",
    )
    parser.add_argument(
        "--node-cap",
        type=int,
        default=DEFAULT_NODE_CAP,
        help="BFS node budget per level",
    )
    args = parser.parse_args()
    gd_path = args.gd
    if not gd_path.is_file():
        repo = Path(__file__).resolve().parents[1]
        gd_path = repo / "godot" / "scripts" / "main.gd"
    if not gd_path.is_file():
        print(f"missing {gd_path}", file=sys.stderr)
        return 2

    levels = parse_levels(gd_path)
    print(f"LEVELS: {len(levels)} entries from {gd_path}")
    failed = 0
    for i, level in enumerate(levels):
        validate_level(level, i)
        colors = sorted({c for t in level for c in t})
        empties = sum(1 for t in level if not t)
        result = solve(level, node_cap=args.node_cap)
        n_tubes = len(level)
        if result["ok"]:
            print(
                f"  level {i + 1:2d}: solvable  "
                f"moves={result['moves']:3d}  nodes={result['nodes']:6d}  "
                f"tubes={n_tubes} colors={len(colors)} empty={empties}"
            )
        else:
            failed += 1
            reason = result.get("reason", "unsolved")
            print(
                f"  level {i + 1:2d}: FAIL ({reason})  "
                f"nodes={result['nodes']}  tubes={n_tubes} "
                f"colors={len(colors)} empty={empties}"
            )

    if failed:
        print(f"UNSOLVED: {failed}/{len(levels)}")
        return 1
    print(f"levels 1–{len(levels)} are solvable")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
