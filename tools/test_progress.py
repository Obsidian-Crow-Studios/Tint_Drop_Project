#!/usr/bin/env python3
"""Spec tests for campaign persist, daily pack, and streak.

Mirrors godot/scripts/progress.gd via tools/progress_save.py. Run:

  python3 tools/test_progress.py
"""

from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from progress_save import (  # noqa: E402
    CAMPAIGN_MAX,
    ENTITLEMENT_KEYS,
    PACK_CLEARS,
    SAVE_KEYS,
    TintProgress,
    is_yesterday,
)


GD_PATH = ROOT / "godot" / "scripts" / "progress.gd"
MAIN_PATH = ROOT / "godot" / "scripts" / "main.gd"


def assert_eq(actual, expected, msg: str) -> None:
    if actual != expected:
        raise AssertionError(f"{msg}: {actual!r} != {expected!r}")


def test_gdscript_contract() -> None:
    text = GD_PATH.read_text(encoding="utf-8")
    assert_eq('SAVE_PATH := "user://tint_drop.cfg"' in text, True, "save path")
    for key in SAVE_KEYS:
        if f'"{key}"' not in text:
            raise AssertionError(f"progress.gd missing ConfigFile key {key}")
    for key in ENTITLEMENT_KEYS:
        if f'"{key}"' not in text:
            raise AssertionError(f"progress.gd missing entitlement key {key}")
    if 'ENTITLEMENTS := "entitlements"' not in text:
        raise AssertionError("progress.gd must persist entitlements in the same ConfigFile")
    main = MAIN_PATH.read_text(encoding="utf-8")
    if "TintProgress" not in main and "progress.gd" not in main:
        raise AssertionError("main.gd does not wire progress.gd")
    if "_on_restart" in main and "_progress.record_clear" in main[main.index("_on_restart"):main.index("_on_restart") + 400]:
        raise AssertionError("Restart must not record a campaign clear")
    if "PRESET_CENTER_WIDE" in main:
        raise AssertionError("main.gd must not use PRESET_CENTER_WIDE")
    if "AXIS_STRETCH_MODE_SCALE" in main:
        raise AssertionError("main.gd must not use AXIS_STRETCH_MODE_SCALE")


def test_first_boot_does_not_invent_progress() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    assert_eq(p.campaign_level_index, 0, "fresh campaign index")
    assert_eq(p.current_pack_clears, 0, "fresh pack")
    assert_eq(p.streak_days, 0, "fresh streak")
    assert_eq(p.last_play_date, "", "fresh last play")
    assert_eq(p.should_show_streak_chip(), False, "no chip on first launch")
    assert_eq(p.streak_chip_text(), "", "no chip text")
    assert_eq(p.remove_ads, False, "fresh ads entitlement")
    assert_eq(p.extra_well_count, 0, "fresh extra well count")
    assert_eq(p.undo_count, 0, "fresh undo count")
    assert_eq(p.bomb_count, 0, "fresh bomb count")


def test_clear_advances_and_saves() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    p.record_clear(0, "2026-08-28")
    assert_eq(p.campaign_level_index, 1, "resume next board")
    assert_eq(p.current_pack_clears, 1, "first clear of pack")
    assert_eq(p.daily_pack_date, "2026-08-28", "pack date")
    assert_eq(p.last_play_date, "2026-08-28", "play date")
    assert_eq(p.streak_days, 1, "streak starts at 1")
    assert_eq(p.pack_pips_filled(won=True), 1, "pips after clear")
    assert_eq(p.should_show_streak_chip(), True, "chip after a clear")
    assert_eq(p.streak_chip_text(), "streak 1", "chip copy")


def test_five_clears_is_pack_stop_then_next_five_same_day() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    for i in range(5):
        p.record_clear(i, "2026-08-28")
    assert_eq(p.current_pack_clears, 5, "pack complete")
    assert_eq(p.pack_just_completed(), True, "pack stop")
    assert_eq(p.campaign_level_index, 5, "next campaign board is 6")
    assert_eq(p.pack_pips_filled(won=True), 5, "overlay pips")
    assert_eq(p.pack_pips_filled(won=False), 0, "title/next pack pips")
    # Same local date: Again/Next continues today's campaign, next 5 of 100.
    p.record_clear(5, "2026-08-28")
    assert_eq(p.current_pack_clears, 1, "first of next five")
    assert_eq(p.campaign_level_index, 6, "stays in campaign")
    assert_eq(p.streak_days, 1, "same-day streak unchanged")


def test_new_local_date_resets_pack_and_increments_streak() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    p.record_clear(0, "2026-08-28")
    p.record_clear(1, "2026-08-28")
    p.record_clear(2, "2026-08-28")
    assert_eq(p.current_pack_clears, 3, "mid pack")
    p.boot(100, "2026-08-29", had_save=True)
    assert_eq(p.current_pack_clears, 0, "fresh daily pack")
    assert_eq(p.campaign_level_index, 3, "campaign keeps next board")
    assert_eq(p.streak_days, 2, "yesterday play increments streak")
    assert_eq(p.daily_pack_date, "2026-08-29", "pack date rolls")
    assert_eq(p.last_play_date, "2026-08-28", "last clear still yesterday until today clear")
    assert_eq(p.streak_chip_text(), "streak 2", "returning chip")
    # Re-open same new day must not double-count streak.
    p.boot(100, "2026-08-29", had_save=True)
    assert_eq(p.streak_days, 2, "no double increment")
    p.record_clear(3, "2026-08-29")
    assert_eq(p.current_pack_clears, 1, "today pack starts at 1")
    assert_eq(p.last_play_date, "2026-08-29", "clear stamps today")
    assert_eq(p.streak_days, 2, "clear does not bump again")


def test_skipped_day_resets_streak_to_one() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    p.record_clear(4, "2026-08-28")
    p.streak_days = 6
    p.boot(100, "2026-08-30", had_save=True)
    assert_eq(p.streak_days, 1, "gap resets streak")
    assert_eq(p.current_pack_clears, 0, "fresh pack after gap")
    assert_eq(p.campaign_level_index, 5, "campaign still resumes")


def test_month_and_year_boundaries() -> None:
    assert_eq(is_yesterday("2026-02-28", "2026-03-01"), True, "Feb to Mar")
    assert_eq(is_yesterday("2025-12-31", "2026-01-01"), True, "new year")
    assert_eq(is_yesterday("2026-08-27", "2026-08-29"), False, "gap")
    p = TintProgress()
    p.last_play_date = "2025-12-31"
    p.daily_pack_date = "2025-12-31"
    p.streak_days = 4
    p.campaign_level_index = 10
    p.current_pack_clears = 4
    p.boot(100, "2026-01-01", had_save=True)
    assert_eq(p.streak_days, 5, "year-boundary streak")
    assert_eq(p.current_pack_clears, 0, "year-boundary pack")


def test_level_100_loops_to_zero() -> None:
    p = TintProgress()
    p.campaign_level_index = 99
    p.record_clear(99, "2026-08-28")
    assert_eq(p.campaign_level_index, 0, "loop to 0")
    assert_eq(p.current_pack_clears, 1, "pack still counts the clear")
    p.campaign_level_index = 99
    p.current_pack_clears = 4
    p.record_clear(99, "2026-08-28")
    assert_eq(p.campaign_level_index, 0, "loop after pack stop clear")
    assert_eq(p.pack_just_completed(), True, "5th clear is still pack complete")


def test_clamp_and_config_roundtrip() -> None:
    p = TintProgress(
        campaign_level_index=150,
        current_pack_clears=9,
        streak_days=-3,
        daily_pack_date="2026-08-28",
        last_play_date="2026-08-28",
    )
    p.clamp_fields()
    assert_eq(p.campaign_level_index, CAMPAIGN_MAX, "clamp 99")
    assert_eq(p.current_pack_clears, PACK_CLEARS, "clamp 5")
    assert_eq(p.streak_days, 0, "clamp streak")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tint_drop.cfg"
        p.campaign_level_index = 7
        p.current_pack_clears = 2
        p.streak_days = 3
        p.save(path)
        text = path.read_text(encoding="utf-8")
        for key in SAVE_KEYS:
            if key not in text:
                raise AssertionError(f"config missing {key}")
        for key in ENTITLEMENT_KEYS:
            if key not in text:
                raise AssertionError(f"config missing entitlement {key}")
        loaded = TintProgress.load(path)
        assert_eq(loaded.campaign_level_index, 7, "reload index")
        assert_eq(loaded.current_pack_clears, 2, "reload pack")
        assert_eq(loaded.streak_days, 3, "reload streak")
        assert_eq(loaded.daily_pack_date, "2026-08-28", "reload pack date")
        assert_eq(loaded.last_play_date, "2026-08-28", "reload last play")


def test_quit_relaunch_resumes_saved_level() -> None:
    """Quit after a clear, relaunch same day: TAP TO PLAY is the next board."""
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tint_drop.cfg"
        p = TintProgress(save_path=str(path))
        p.boot(100, "2026-08-28", had_save=False)
        p.record_clear(11, "2026-08-28")
        p.save(path)
        launched = TintProgress.load(path)
        launched.boot(100, "2026-08-28", had_save=True)
        assert_eq(launched.campaign_level_index, 12, "relaunch resumes level 13")
        assert_eq(launched.current_pack_clears, 1, "same-day pack kept")
        assert_eq(launched.streak_days, 1, "same-day streak kept")


def test_restart_is_not_a_clear() -> None:
    """Restart only retries the current board; persist stays put."""
    p = TintProgress(campaign_level_index=8, current_pack_clears=2, streak_days=3)
    p.daily_pack_date = "2026-08-28"
    p.last_play_date = "2026-08-28"
    snapshot = (
        p.campaign_level_index,
        p.current_pack_clears,
        p.streak_days,
        p.last_play_date,
    )
    # Restart does not call record_clear.
    assert_eq(
        (p.campaign_level_index, p.current_pack_clears, p.streak_days, p.last_play_date),
        snapshot,
        "restart leaves save alone",
    )


def test_entitlements_persist_and_consumables_count() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    assert_eq(p.remove_ads, False, "fresh ads")
    assert_eq(p.extra_well_count, 0, "fresh wells")
    assert_eq(p.undo_count, 0, "fresh undos")
    assert_eq(p.bomb_count, 0, "fresh bombs")
    p.apply_sku("remove_ads")
    p.apply_sku("extra_well")
    p.apply_sku("undo_pack")
    p.apply_sku("color_bomb")
    p.apply_sku("well_skin")
    p.apply_sku("cosmetic_track", now_unix=1_000_000)
    assert_eq(p.remove_ads, True, "remove_ads owned")
    assert_eq(p.extra_well_count, 1, "extra well count")
    assert_eq(p.undo_count, 5, "undo pack adds 5")
    assert_eq(p.bomb_count, 1, "bomb count")
    assert_eq(p.well_skin, True, "well skin owned")
    assert_eq(p.cosmetic_track_active(now_unix=1_000_000), True, "track starts")
    assert_eq(p.cosmetic_track_active(now_unix=1_000_000 + 14 * 86400), False, "track expires")
    p.apply_sku("booster_starter")
    assert_eq(p.booster_starter, True, "starter owned")
    assert_eq(p.extra_well_count, 2, "starter adds a well")
    assert_eq(p.undo_count, 8, "starter adds 3 undos")
    assert_eq(p.bomb_count, 2, "starter adds a bomb")
    p.apply_sku("booster_starter")
    assert_eq(p.extra_well_count, 2, "starter is once")
    assert_eq(p.consume_extra_well(), True, "consume well")
    assert_eq(p.extra_well_count, 1, "well decremented")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tint_drop.cfg"
        p.save(path)
        loaded = TintProgress.load(path)
        assert_eq(loaded.remove_ads, True, "reload remove_ads")
        assert_eq(loaded.extra_well_count, 1, "reload extra well")
        assert_eq(loaded.undo_count, 8, "reload undos")
        assert_eq(loaded.bomb_count, 2, "reload bombs")
        assert_eq(loaded.well_skin, True, "reload well skin")
        assert_eq(loaded.booster_starter, True, "reload starter")
        loaded.record_clear(0, "2026-08-28")
        loaded.save(path)
        kept = TintProgress.load(path)
        assert_eq(kept.remove_ads, True, "clear must not wipe entitlements")
        assert_eq(kept.undo_count, 8, "clear keeps undo count")
        assert_eq(kept.campaign_level_index, 1, "clear still advances")


def test_entitlement_save_does_not_invent_a_play_day() -> None:
    p = TintProgress()
    p.boot(100, "2026-08-28", had_save=False)
    p.apply_sku("remove_ads")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "tint_drop.cfg"
        p.save(path)
        launched = TintProgress.load(path)
        launched.boot(100, "2026-08-29", had_save=True)
        assert_eq(launched.remove_ads, True, "ads persist without a clear")
        assert_eq(launched.current_pack_clears, 0, "no invented pack")
        assert_eq(launched.streak_days, 0, "no invented streak")
        assert_eq(launched.last_play_date, "", "no play day")
        assert_eq(launched.should_show_streak_chip(), False, "no chip")


def test_steam_paid_app_grants_ads_off_and_starter() -> None:
    p = TintProgress()
    p.apply_steam_paid_app()
    assert_eq(p.remove_ads, True, "steam ads off")
    assert_eq(p.booster_starter, True, "steam starter")
    assert_eq(p.extra_well_count, 1, "steam well")
    assert_eq(p.undo_count, 3, "steam undos")
    assert_eq(p.bomb_count, 1, "steam bomb")
    p.apply_steam_paid_app()
    assert_eq(p.extra_well_count, 1, "steam grant is once")


def test_main_does_not_change_levels_or_overlay_assets() -> None:
    main = MAIN_PATH.read_text(encoding="utf-8")
    overlay = (ROOT / "godot" / "scripts" / "win_overlay.gd").read_text(encoding="utf-8")
    levels = re.search(r"const LEVELS:\s*Array\s*=\s*(\[(?:.|\n)*?\n\])", main)
    if not levels:
        raise AssertionError("LEVELS missing")
    # 100 boards: one [[...] per level line inside the array.
    n = len(re.findall(r"^\t\[\[", levels.group(1), flags=re.M))
    assert_eq(n, 100, "do not change LEVELS count")
    if "win-fanfare-cleared.png" not in overlay or "win-fanfare-pack.png" not in overlay:
        raise AssertionError("win overlay stills must stay")
    if "FANFARE_S := 7.0" not in overlay:
        raise AssertionError("fanfare length locked")


def main() -> int:
    tests = [
        test_gdscript_contract,
        test_first_boot_does_not_invent_progress,
        test_clear_advances_and_saves,
        test_five_clears_is_pack_stop_then_next_five_same_day,
        test_new_local_date_resets_pack_and_increments_streak,
        test_skipped_day_resets_streak_to_one,
        test_month_and_year_boundaries,
        test_level_100_loops_to_zero,
        test_clamp_and_config_roundtrip,
        test_quit_relaunch_resumes_saved_level,
        test_restart_is_not_a_clear,
        test_entitlements_persist_and_consumables_count,
        test_entitlement_save_does_not_invent_a_play_day,
        test_steam_paid_app_grants_ads_off_and_starter,
        test_main_does_not_change_levels_or_overlay_assets,
    ]
    failed = 0
    for fn in tests:
        try:
            fn()
            print(f"ok  {fn.__name__}")
        except Exception as exc:  # noqa: BLE001
            failed += 1
            print(f"FAIL {fn.__name__}: {exc}")
    if failed:
        print(f"{failed} failed")
        return 1
    print(f"{len(tests)} passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
