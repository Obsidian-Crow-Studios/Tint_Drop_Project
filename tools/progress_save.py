#!/usr/bin/env python3
"""Campaign persist + daily pack + streak. Keep in sync with godot/scripts/progress.gd."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path

PACK_CLEARS = 5
CAMPAIGN_MAX = 99
SECTION = "progress"
SAVE_KEYS = (
    "campaign_level_index",
    "current_pack_clears",
    "daily_pack_date",
    "streak_days",
    "last_play_date",
)


def format_ymd(year: int, month: int, day: int) -> str:
    return f"{year:04d}-{month:02d}-{day:02d}"


def parse_ymd(s: str) -> date | None:
    if not s:
        return None
    try:
        return date.fromisoformat(s)
    except ValueError:
        return None


def is_yesterday(prev: str, today: str) -> bool:
    p = parse_ymd(prev)
    t = parse_ymd(today)
    if p is None or t is None:
        return False
    return t - p == timedelta(days=1)


@dataclass
class TintProgress:
    campaign_level_index: int = 0
    current_pack_clears: int = 0
    daily_pack_date: str = ""
    streak_days: int = 0
    last_play_date: str = ""
    save_path: str = ""
    level_count: int = 100

    def _last_index(self) -> int:
        return min(CAMPAIGN_MAX, max(self.level_count, 1) - 1)

    def clamp_fields(self) -> None:
        last_i = self._last_index()
        self.campaign_level_index = max(0, min(self.campaign_level_index, last_i))
        self.current_pack_clears = max(0, min(self.current_pack_clears, PACK_CLEARS))
        self.streak_days = max(self.streak_days, 0)

    def apply_daily_rollover(self, today: str) -> None:
        if not today or self.daily_pack_date == today:
            return
        self.current_pack_clears = 0
        self.daily_pack_date = today
        if is_yesterday(self.last_play_date, today):
            self.streak_days = max(self.streak_days, 0) + 1
        else:
            self.streak_days = 1

    def boot(self, level_count: int, today: str, had_save: bool) -> None:
        self.level_count = max(level_count, 1)
        self.clamp_fields()
        if had_save:
            self.apply_daily_rollover(today)
        else:
            self.daily_pack_date = ""
            self.current_pack_clears = 0
            self.streak_days = 0
            self.last_play_date = ""
            self.campaign_level_index = 0

    def record_clear(self, cleared_index: int, today: str, level_count: int | None = None) -> None:
        if level_count is not None:
            self.level_count = level_count
        last_i = self._last_index()
        cleared = max(0, min(cleared_index, last_i))
        if cleared >= last_i:
            self.campaign_level_index = 0
        else:
            self.campaign_level_index = cleared + 1
        if self.current_pack_clears >= PACK_CLEARS:
            self.current_pack_clears = 1
        else:
            self.current_pack_clears = max(0, min(self.current_pack_clears + 1, PACK_CLEARS))
        self.daily_pack_date = today
        self.last_play_date = today
        if self.streak_days <= 0:
            self.streak_days = 1
        self.clamp_fields()

    def pack_pips_filled(self, won: bool) -> int:
        filled = self.current_pack_clears
        if filled >= PACK_CLEARS and not won:
            return 0
        return max(0, min(filled, PACK_CLEARS))

    def pack_just_completed(self) -> bool:
        return self.current_pack_clears >= PACK_CLEARS

    def should_show_streak_chip(self) -> bool:
        return self.streak_days >= 1 and bool(self.last_play_date)

    def streak_chip_text(self) -> str:
        if not self.should_show_streak_chip():
            return ""
        return f"streak {self.streak_days}"

    def to_config(self) -> str:
        self.clamp_fields()
        lines = [
            f"[{SECTION}]",
            "",
            f"campaign_level_index={self.campaign_level_index}",
            f"current_pack_clears={self.current_pack_clears}",
            f'daily_pack_date="{self.daily_pack_date}"',
            f"streak_days={self.streak_days}",
            f'last_play_date="{self.last_play_date}"',
            "",
        ]
        return "\n".join(lines)

    @classmethod
    def from_config(cls, text: str, save_path: str = "") -> TintProgress:
        data: dict[str, str] = {}
        for raw in text.splitlines():
            line = raw.strip()
            if not line or line.startswith("[") or line.startswith(";"):
                continue
            if "=" not in line:
                continue
            key, val = line.split("=", 1)
            data[key.strip()] = val.strip().strip('"')
        prog = cls(save_path=save_path)
        prog.campaign_level_index = int(data.get("campaign_level_index", "0") or 0)
        prog.current_pack_clears = int(data.get("current_pack_clears", "0") or 0)
        prog.daily_pack_date = data.get("daily_pack_date", "")
        prog.streak_days = int(data.get("streak_days", "0") or 0)
        prog.last_play_date = data.get("last_play_date", "")
        prog.clamp_fields()
        return prog

    def save(self, path: str | Path | None = None) -> None:
        dest = Path(path or self.save_path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(self.to_config(), encoding="utf-8")

    @classmethod
    def load(cls, path: str | Path, level_count: int = 100) -> TintProgress:
        p = Path(path)
        if not p.is_file():
            prog = cls(save_path=str(p), level_count=level_count)
            return prog
        prog = cls.from_config(p.read_text(encoding="utf-8"), save_path=str(p))
        prog.level_count = level_count
        prog.clamp_fields()
        return prog
