# Tint Drop

Color-sort (water-tube) puzzle for **Godot 4.7**. Obsidian Crow Studios. Hybridcasual, no gacha.

Import the inner `godot/` folder, then F5. Portrait is 720×1280.

## Play

- **TAP TO PLAY**, then sort tubes before the 60s clock runs out. Progress saves locally (`user://tint_drop.cfg`). TAP TO PLAY resumes the campaign; **Restart** only retries the current board.
- Tap a tube to pick its **top color run**. Tap another to **pour** (empty, or same color with space).
- **Undo** / **Restart**. Five clears is today’s pack. A new local date starts a fresh 5-level pack and updates the streak (small chip on TAP TO PLAY). One hundred campaign levels; after 100 the campaign loops to 1. **Shop** is an IAP stub.

## Contribute

The repo is public. You do not need write access.

1. Fork.
2. Branch off `main`.
3. Keep Godot **4.7**. Do not use `PRESET_CENTER_WIDE` or NinePatch `AXIS_STRETCH_MODE_SCALE`.
4. Follow [`GAME_DESIGN.md`](GAME_DESIGN.md). No loot boxes, gacha, or pay-to-not-suffer.
5. New levels go in `godot/scripts/main.gd` (`LEVELS`) and must pass `python3 tools/solve_levels.py`. Persist / daily pack: `python3 tools/test_progress.py`.
6. Open a pull request.

Art is Super Grok / Grok Imagine. Audio is wavs in `godot/assets/`. Code reviews happen on GitHub PRs.
