# Tint Drop — Design One-Pager

**Working title:** Tint Drop  
**Engine:** Godot 4 (one project, three exports)  
**Stores:** App Store, Google Play, Steam  
**Business:** cash-first hybridcasual puzzle. Outrage Odyssey stays the long game.  
**Status:** locked 2026-08-24. This file is direction. Chat does not override it.

---

## 1. Pitch

Tap and send falling color chips into matching wells. Sixty-second levels. Clear the board, or you retry. No story campaign to produce. The juice is the clear, the streak, and tomorrow’s new pack.

## 2. Why this, not match-3 / merge

H1 2026 puzzle IAP is huge, but match-3 is a fortress (almost no new title clears real money) and merge-2 is a content factory. Sort / screw / block is the cheap-to-build lane (Pixel Flow, Screwdom, Color Block Jam). We ship a **sort** core.

## 3. Core loop (one session)

1. Open app → daily streak chip (if returning).
2. Play a level (~45–90s). Tap a chip or well to route matching colors.
3. Win → next level. Lose → retry (one free retry, then a booster, rewarded ad, or wait).
4. Session goal: 3–5 clears, then a natural stop. No infinite energy wall on day one.
5. Come back tomorrow for the daily pack + streak.

## 4. Feel

Satisfying, readable, one-thumb. Fail is obvious. Retry is cheap. Never a slot machine.

## 5. Platforms

| Store | Build | Money |
|-------|--------|--------|
| iOS / Android | Free | IAP + rewarded ads |
| Steam | Same game | Paid unlock **or** no-ads included (no rewarded ads) |

One Godot project. Export presets, not three games.

## 6. Monetization (locked)

USD list prices locked 2026-08-28. Stores take ~30%. First 50 levels stay free. No $4.99 fail-wall.

**Mobile IAP**

Store product IDs: `com.obsidiancrow.tintdrop.<sku_id>` (example `com.obsidiancrow.tintdrop.remove_ads`).

- Remove ads — $4.99 — `remove_ads`
- Extra well — $1.99 — `extra_well`
- Undo pack (5) — $1.99 — `undo_pack`
- Color-bomb — $1.99 — `color_bomb`
- Booster starter (1 extra well + 3 undos + 1 bomb) — $4.99 — `booster_starter`
- Well skin or chip trail — $0.99 — `well_skin`
- 14-day cosmetic track (no level paywall) — $4.99 — `cosmetic_track`
- Rewarded ads: extra retry or one booster (opt-in, never forced mid-clear). No price.

**Steam**
- $7.99 one purchase: the game with ads off + booster starter kit. No rewarded ads on Steam. No mobile IAP catalog.

**Forbidden**
- Loot boxes, gacha, randomized paid packs
- Pay-to-not-suffer as the only way past a wall
- Fake money / casino chrome
- Dark patterns that hide the price or the close button

## 7. Retention (fair, not a trap)

- Daily streak with a **streak freeze** you can earn, not only buy
- Daily 5-level pack
- Near-miss is a fair fail, not a rigged last-chip
- First 50 levels playable without spending
- No countdown that only stops if you pay

## 8. Content target for v1

- 100 hand-tuned levels (not 1000 procedural dumps)
- 10 “hard” marked levels
- 3 boosters
- 5 cosmetic wells
- iOS + Android + Steam export from the same `godot/` folder

## 9. Prototype (this week)

F5 playable: 100 levels, win/lose, retry, Shop catalog with locked list prices. Editor / desktop does not charge (toast “Not billed yet.”). No live store accounts required.

## 10. Out of scope for v1

Narrative, meta-city, chat, UGC, Odyssey crossovers, match-3, merge boards.

