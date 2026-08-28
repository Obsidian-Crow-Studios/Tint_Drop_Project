#!/usr/bin/env python3
"""Spec tests for locked v1 Shop list prices (unpaid stub).

Run:

  python3 tools/test_shop.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAIN_PATH = ROOT / "godot" / "scripts" / "main.gd"
OVERLAY_PATH = ROOT / "godot" / "scripts" / "win_overlay.gd"
DESIGN_PATH = ROOT / "GAME_DESIGN.md"

# Locked 2026-08-28 mobile IAP list. Do not invent others.
LOCKED_SKUS = [
    ("Remove ads", "$4.99"),
    ("Extra well", "$1.99"),
    ("Undo pack (5)", "$1.99"),
    ("Color-bomb", "$1.99"),
    ("Booster starter (1 extra well + 3 undos + 1 bomb)", "$4.99"),
    ("Well skin or chip trail", "$0.99"),
    ("14-day cosmetic track", "$4.99"),
]


def assert_eq(actual, expected, msg: str) -> None:
    if actual != expected:
        raise AssertionError(f"{msg}: {actual!r} != {expected!r}")


def _shop_skus(main: str) -> list[tuple[str, str, str]]:
    block = re.search(r"const SHOP_SKUS:\s*Array\s*=\s*\[((?:.|\n)*?)\n\]", main)
    if not block:
        raise AssertionError("SHOP_SKUS missing")
    rows = re.findall(
        r'\["([^"]+)",\s*"(\$[0-9]+\.[0-9]{2})",\s*"([^"]+)"\]',
        block.group(1),
    )
    if not rows:
        raise AssertionError("SHOP_SKUS has no priced rows")
    return [(n, p, i) for n, p, i in rows]


def test_locked_prices_match_game_design() -> None:
    design = DESIGN_PATH.read_text(encoding="utf-8")
    if "USD list prices locked 2026-08-28" not in design:
        raise AssertionError("GAME_DESIGN.md missing 2026-08-28 price lock")
    for name, price in LOCKED_SKUS:
        if name.split(" (")[0] not in design and name not in design:
            raise AssertionError(f"GAME_DESIGN.md missing {name}")
        if price not in design:
            raise AssertionError(f"GAME_DESIGN.md missing {price} for {name}")


def test_shop_lists_locked_skus() -> None:
    main = MAIN_PATH.read_text(encoding="utf-8")
    rows = _shop_skus(main)
    listed = [(n, p) for n, p, _i in rows]
    assert_eq(listed, LOCKED_SKUS, "shop SKUs")
    ids = [i for _n, _p, i in rows]
    if len(ids) != len(set(ids)):
        raise AssertionError("duplicate shop sku ids")
    if "$7.99" in "".join(p for _n, p, _i in rows):
        raise AssertionError("Steam SKU does not belong on the mobile Shop sheet")


def test_shop_is_unpaid_stub() -> None:
    main = MAIN_PATH.read_text(encoding="utf-8")
    forbidden = (
        "StoreKit",
        "SKPayment",
        "GodotGooglePlayBilling",
        "in_app_purchase",
        "Purchasing.IAP",
        "BillingClient",
    )
    for token in forbidden:
        if token in main:
            raise AssertionError(f"shop must not wire real billing ({token})")
    if "Not billed yet." not in main:
        raise AssertionError("unpaid SKUs must toast that nothing is billed")
    if "print(\"IAP later\")" not in main:
        raise AssertionError("stub must still log IAP later")
    if "_apply_extra_well" not in main:
        raise AssertionError("extra well prototype grant must stay")
    if "List prices. Nothing charged." not in main:
        raise AssertionError("shop sheet must say nothing is charged")


def test_shop_keeps_wood_icing_and_godot_constraints() -> None:
    main = MAIN_PATH.read_text(encoding="utf-8")
    overlay = OVERLAY_PATH.read_text(encoding="utf-8")
    if "PRESET_CENTER_WIDE" in main:
        raise AssertionError("main.gd must not use PRESET_CENTER_WIDE")
    if "AXIS_STRETCH_MODE_SCALE" in main:
        raise AssertionError("main.gd must not use AXIS_STRETCH_MODE_SCALE")
    shop = main[main.index("func _build_shop_panel") :]
    shop = shop[: shop.index("func _on_shop(")]
    if "_add_walnut_icing(_shop_panel)" not in shop:
        raise AssertionError("shop sheet must stay walnut icing")
    if "TEX_BOARD_HERO" not in shop:
        raise AssertionError("shop sheet must keep board-hero plaque")
    if "gold" in shop.lower() or "casino" in shop.lower():
        raise AssertionError("no gold/casino chrome on shop")
    if "FANFARE_S := 7.0" not in overlay:
        raise AssertionError("overlay lock must stay untouched")
    if "win-fanfare-cleared.png" not in overlay or "win-fanfare-pack.png" not in overlay:
        raise AssertionError("overlay stills must stay")


def main() -> int:
    tests = [
        test_locked_prices_match_game_design,
        test_shop_lists_locked_skus,
        test_shop_is_unpaid_stub,
        test_shop_keeps_wood_icing_and_godot_constraints,
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
