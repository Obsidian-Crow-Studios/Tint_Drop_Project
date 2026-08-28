extends Control

const TubeView = preload("res://scripts/tube.gd")
const LogoMarkScript = preload("res://scripts/logo_mark.gd")
const WinOverlayScript = preload("res://scripts/win_overlay.gd")
const TintProgressScript = preload("res://scripts/progress.gd")
const CAPACITY := 4
const TUBE_SCENE_W := 144.0
const TUBE_SCENE_H := 282.0
const LEVEL_TIME := 90.0
const PACK_CLEARS := 5
const SFX_PICK := preload("res://assets/sfx/sfx_pick.wav")
const SFX_POUR := preload("res://assets/sfx/sfx_pour.wav")
const SFX_INVALID := preload("res://assets/sfx/sfx_invalid.wav")
const SFX_CLEAR := preload("res://assets/sfx/sfx_clear.wav")
const SFX_UNDO := preload("res://assets/sfx/sfx_undo.wav")
const SFX_RESTART := preload("res://assets/sfx/sfx_restart.wav")
const SFX_NEXT := preload("res://assets/sfx/sfx_next.wav")
const SFX_COMBO := preload("res://assets/sfx/sfx_combo.wav")
const SFX_CHEER_MATCH := preload("res://assets/sfx/sfx_cheer_match.wav")
const SFX_CHEER_CLEAR := preload("res://assets/sfx/sfx_cheer_clear.wav")
const SFX_LOSE := preload("res://assets/sfx/sfx_lose.wav")
const BGM_PLAY := preload("res://assets/music/bgm_play.wav")
const BGM_VOL := -8.0
const BGM_DUCK := -14.0
const UI_FILL := Color8(59, 30, 22, 230)
const UI_RIM := Color8(232, 213, 196)
const UI_CAPTION := Color8(243, 230, 216)
const UI_BTN_FILL := Color8(74, 38, 28)
const UI_NUM := Color8(243, 230, 216)
const UI_HERO := Color8(224, 122, 74)
const UI_SHEEN := Color8(92, 51, 40)
const UI_ESPRESSO := Color8(59, 30, 22, 255)
## Locked 2026-08-28 mobile IAP list prices. Shop is an unpaid stub.
const SHOP_CAPTION := "List prices. Nothing charged."
const SHOP_SKUS: Array = [
	["Remove ads", "$4.99", "remove_ads"],
	["Extra well", "$1.99", "extra_well"],
	["Undo pack (5)", "$1.99", "undo_pack"],
	["Color-bomb", "$1.99", "color_bomb"],
	["Booster starter (1 extra well + 3 undos + 1 bomb)", "$4.99", "booster_starter"],
	["Well skin or chip trail", "$0.99", "well_skin"],
	["14-day cosmetic track", "$4.99", "cosmetic_track"],
]
const HINT_FONT := preload("res://assets/ui/fonts/BubblegumSans-Regular.ttf")
const CAFE_BG := preload("res://assets/crowd/cafe-bg.png")
const TEX_TABLE_WATCH := preload("res://assets/crowd/table-watch.png")
const TEX_TABLE_CHEER := preload("res://assets/crowd/table-cheer.png")
const TEX_TABLE_GROAN_PATH := "res://assets/crowd/table-groan.png"
const TEX_BOARD_HERO := preload("res://assets/ui/board-hero.png")
const TEX_BOARD_TILE := preload("res://assets/ui/board-tile.png")
const TEX_BOARD_BTN := preload("res://assets/ui/board-btn.png")
const TEX_HINT_TAP := preload("res://assets/ui/hint-tap-a-tube.png")
const TEX_PIP_EMPTY := preload("res://assets/ui/pip_empty_20.png")
const TEX_PIP_LIT := preload("res://assets/ui/pip_lit_20.png")
const CROWD_WATCH := 0
const CROWD_CHEER := 1
const CROWD_GROAN := 2

## Bottom → top. Color ids 0..5. Empty tubes are [].
const LEVELS: Array = [
	[[0, 0, 0, 1], [1, 1, 1, 0], []],
	[[0, 1, 1, 0], [1, 0, 0, 1], []],
	[[0, 1, 0, 1], [1, 0, 1, 0], []],
	[[0, 1, 2, 0], [1, 2, 0, 1], [2, 0, 1, 2], [], []],
	[[0, 0, 1, 2], [1, 2, 0, 1], [2, 1, 2, 0], [], []],
	[[0, 1, 2, 0], [1, 2, 0, 1], [2, 0, 1, 2], []],
	[[0, 1, 2, 3], [3, 0, 1, 2], [2, 3, 0, 1], [1, 2, 3, 0], [], []],
	[[0, 1, 2, 3], [1, 2, 3, 0], [2, 0, 1, 3], [3, 1, 0, 2], [], []],
	[[0, 3, 1, 2], [1, 0, 2, 3], [2, 1, 3, 0], [3, 2, 0, 1], [], []],
	[[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0], []],
	[[0, 1, 2, 0], [1, 2, 3, 1], [2, 3, 0, 2], [3, 0, 1, 3], [], []],
	[[0, 2, 3, 1], [1, 3, 2, 0], [2, 0, 1, 3], [3, 1, 0, 2], [], []],
	[[0, 1, 2, 3], [3, 2, 1, 0], [0, 3, 1, 2], [2, 1, 3, 0], [], []],
	[[0, 2, 0, 2], [1, 3, 1, 3], [2, 0, 3, 1], [3, 1, 2, 0], [], []],
	[[0, 1, 0, 1], [2, 3, 2, 3], [1, 0, 3, 2], [3, 2, 1, 0], []],
	[[0, 3, 1, 2], [1, 2, 0, 3], [2, 1, 3, 0], [3, 0, 2, 1], []],
	[[0, 1, 2, 3], [2, 3, 0, 1], [1, 0, 3, 2], [3, 2, 1, 0], []],
	[[0, 1, 2, 1], [1, 0, 3, 0], [2, 3, 0, 3], [3, 2, 1, 2], []],
	[[1, 2, 3, 2], [0, 1, 0, 3], [1, 2, 1, 0], [2, 3, 0, 3], []],
	[[0, 2, 3, 2], [3, 1, 3, 0], [2, 1, 0, 2], [0, 1, 3, 1], []],
	[[0, 1, 2, 3], [1, 2, 3, 4], [2, 3, 4, 0], [3, 4, 0, 1], [4, 0, 1, 2], []],
	[[0, 1, 2, 0], [1, 2, 3, 1], [2, 3, 4, 2], [3, 4, 0, 3], [4, 0, 1, 4], []],
	[[0, 2, 1, 3], [4, 1, 0, 2], [3, 4, 2, 0], [1, 3, 4, 2], [0, 1, 3, 4], []],
	[[0, 4, 0, 4], [1, 3, 1, 3], [2, 0, 2, 1], [4, 2, 3, 0], [1, 3, 2, 4], []],
	[[0, 2, 1, 0], [3, 1, 4, 3], [2, 4, 0, 2], [1, 3, 2, 4], [4, 0, 3, 1], []],
	[[0, 1, 2, 0], [1, 3, 0, 4], [2, 4, 1, 3], [4, 2, 3, 1], [3, 0, 4, 2], []],
	[[2, 0, 3, 1], [0, 1, 3, 2], [4, 0, 4, 3], [3, 1, 0, 4], [2, 1, 2, 4], []],
	[[4, 1, 2, 0], [4, 1, 3, 1], [3, 2, 1, 4], [2, 3, 4, 0], [0, 2, 3, 0], []],
	[[2, 3, 2, 1], [2, 1, 0, 2], [4, 0, 4, 3], [1, 3, 4, 3], [1, 0, 4, 0], []],
	[[4, 0, 2, 0], [2, 4, 0, 1], [3, 1, 4, 2], [0, 4, 3, 1], [3, 1, 2, 3], []],
	[[0, 1, 4, 2], [1, 3, 4, 3], [1, 3, 1, 4], [0, 3, 0, 2], [2, 0, 2, 4], []],
	[[4, 0, 1, 0], [1, 2, 3, 2], [3, 4, 2, 3], [1, 2, 1, 0], [4, 0, 4, 3], []],
	[[4, 0, 1, 2], [0, 3, 1, 3], [0, 1, 0, 1], [4, 2, 4, 2], [3, 4, 2, 3], []],
	[[1, 4, 0, 4], [4, 2, 4, 3], [0, 2, 0, 2], [3, 1, 0, 1], [3, 2, 3, 1], []],
	[[0, 2, 4, 1], [2, 3, 1, 3], [2, 0, 2, 4], [0, 3, 0, 4], [1, 4, 1, 3], []],
	[[1, 4, 1, 4], [1, 4, 0, 3], [0, 3, 0, 2], [0, 3, 4, 2], [2, 1, 2, 3], []],
	[[1, 4, 0, 3], [4, 2, 0, 2], [4, 0, 4, 0], [1, 2, 1, 3], [3, 1, 3, 2], []],
	[[3, 2, 1, 2], [1, 4, 2, 0], [1, 4, 1, 4], [2, 3, 0, 3], [0, 4, 0, 3], []],
	[[3, 1, 3, 0], [4, 2, 3, 2], [0, 1, 4, 1], [0, 1, 0, 2], [4, 2, 4, 3], []],
	[[3, 0, 1, 0], [2, 4, 0, 2], [0, 3, 1, 3], [2, 4, 2, 3], [1, 4, 1, 4], []],
	[[0, 3, 0, 3], [2, 4, 2, 3], [1, 3, 1, 4], [2, 0, 1, 0], [2, 4, 1, 4], []],
	[[3, 4, 3, 4], [2, 3, 2, 0], [1, 3, 0, 1], [2, 0, 4, 0], [2, 1, 4, 1], []],
	[[3, 2, 3, 2], [4, 2, 4, 1], [1, 4, 1, 3], [0, 2, 3, 0], [4, 0, 1, 0], []],
	[[2, 4, 2, 4], [3, 4, 1, 3], [1, 0, 2, 0], [4, 3, 1, 3], [0, 1, 2, 0], []],
	[[1, 0, 1, 0], [1, 4, 1, 4], [2, 3, 2, 4], [2, 3, 0, 3], [2, 4, 0, 3], []],
	[[0, 4, 0, 4], [3, 1, 3, 1], [4, 2, 4, 1], [0, 2, 3, 2], [0, 1, 3, 2], []],
	[[4, 3, 4, 3], [0, 1, 0, 1], [2, 1, 3, 2], [0, 2, 4, 2], [0, 1, 3, 4], []],
	[[0, 2, 0, 2], [3, 1, 3, 1], [2, 4, 0, 4], [3, 2, 0, 4], [1, 4, 3, 1], []],
	[[0, 3, 0, 3], [2, 4, 2, 4], [3, 0, 1, 3], [2, 4, 1, 2], [1, 4, 0, 1], []],
	[[1, 0, 1, 0], [0, 1, 0, 1], [4, 2, 4, 3], [3, 4, 3, 2], [4, 2, 3, 2], []],
	[[3, 5, 4, 1], [0, 3, 0, 3], [2, 1, 2, 5], [4, 0, 4, 0], [1, 3, 1, 4], [2, 5, 2, 5], []],
	[[0, 2, 0, 2], [4, 1, 4, 1], [3, 5, 3, 5], [1, 0, 4, 1], [2, 0, 2, 3], [5, 4, 5, 3], []],
	[[3, 5, 4, 1], [0, 3, 0, 3], [2, 1, 2, 1], [4, 0, 4, 0], [1, 3, 5, 4], [2, 5, 2, 5], []],
	[[1, 5, 1, 5], [5, 2, 5, 2], [1, 4, 1, 0], [4, 0, 3, 0], [2, 3, 2, 3], [4, 0, 4, 3], []],
	[[4, 5, 0, 5], [2, 4, 1, 2], [3, 0, 1, 3], [1, 4, 1, 4], [2, 0, 2, 0], [5, 3, 5, 3], []],
	[[4, 5, 1, 5], [2, 4, 1, 3], [5, 3, 5, 3], [2, 0, 2, 0], [0, 3, 2, 0], [1, 4, 1, 4], []],
	[[2, 3, 2, 1], [3, 4, 3, 2], [0, 5, 0, 5], [0, 5, 0, 5], [3, 1, 4, 1], [1, 4, 2, 4], []],
	[[2, 1, 2, 1], [2, 3, 4, 3], [0, 5, 0, 5], [0, 5, 0, 5], [3, 1, 4, 1], [3, 4, 2, 4], []],
	[[1, 5, 1, 5], [2, 3, 5, 2], [1, 2, 3, 0], [4, 0, 3, 0], [4, 1, 5, 3], [4, 0, 4, 2], []],
	[[1, 5, 2, 1], [2, 3, 5, 0], [2, 3, 4, 3], [5, 1, 2, 1], [0, 4, 0, 4], [5, 0, 4, 3], []],
	[[0, 5, 3, 0], [4, 0, 5, 2], [1, 2, 5, 2], [1, 4, 3, 5], [1, 2, 1, 0], [3, 4, 3, 4], []],
	[[2, 0, 2, 0], [1, 4, 2, 4], [0, 4, 1, 5], [3, 5, 1, 5], [3, 0, 2, 1], [3, 5, 3, 4], []],
	[[0, 1, 0, 5], [0, 3, 4, 2], [0, 1, 2, 1], [3, 5, 2, 1], [2, 5, 4, 5], [3, 4, 3, 4], []],
	[[1, 0, 5, 0], [5, 4, 5, 4], [2, 3, 1, 2], [3, 4, 5, 0], [0, 1, 3, 4], [3, 2, 1, 2], []],
	[[1, 5, 4, 5], [1, 3, 2, 0], [4, 0, 1, 3], [5, 1, 5, 4], [4, 0, 2, 0], [2, 3, 2, 3], []],
	[[1, 2, 1, 2], [0, 3, 5, 0], [5, 4, 1, 4], [3, 1, 2, 4], [5, 4, 3, 2], [3, 0, 5, 0], []],
	[[4, 3, 0, 4], [3, 4, 0, 4], [0, 5, 3, 2], [3, 2, 5, 1], [0, 5, 1, 5], [1, 2, 1, 2], []],
	[[4, 1, 2, 5], [2, 0, 4, 0], [2, 5, 3, 1], [0, 2, 4, 0], [4, 1, 3, 1], [3, 5, 3, 5], []],
	[[5, 2, 0, 2], [0, 1, 0, 1], [3, 4, 5, 3], [4, 1, 0, 2], [5, 2, 4, 1], [4, 3, 5, 3], []],
	[[1, 3, 2, 0], [4, 0, 2, 0], [2, 3, 2, 3], [4, 0, 1, 3], [5, 1, 4, 5], [1, 5, 4, 5], []],
	[[3, 1, 5, 1], [3, 0, 4, 2], [1, 3, 5, 1], [5, 2, 4, 2], [4, 0, 4, 0], [5, 2, 3, 0], []],
	[[4, 1, 5, 3], [2, 4, 0, 2], [0, 3, 5, 3], [5, 1, 5, 1], [0, 3, 4, 1], [4, 2, 0, 2], []],
	[[3, 5, 1, 3], [1, 4, 0, 4], [0, 2, 0, 2], [1, 4, 5, 2], [5, 3, 1, 3], [5, 2, 0, 4], []],
	[[2, 5, 1, 5], [1, 3, 1, 3], [2, 5, 0, 3], [0, 4, 2, 4], [0, 3, 1, 5], [4, 0, 2, 4], []],
	[[2, 4, 2, 4], [3, 0, 1, 4], [1, 5, 3, 5], [1, 4, 2, 0], [5, 1, 3, 5], [3, 0, 2, 0], []],
	[[4, 0, 5, 0], [5, 2, 4, 3], [1, 3, 1, 3], [5, 2, 1, 2], [0, 4, 5, 0], [4, 3, 1, 2], []],
	[[5, 1, 0, 5], [0, 3, 4, 3], [4, 2, 4, 2], [0, 3, 1, 2], [1, 5, 0, 5], [1, 2, 4, 3], []],
	[[2, 3, 1, 2], [3, 4, 0, 5], [3, 2, 1, 2], [1, 5, 3, 4], [0, 4, 0, 4], [1, 5, 0, 5], []],
	[[3, 0, 5, 1], [2, 1, 2, 1], [3, 0, 2, 0], [4, 5, 3, 4], [5, 1, 2, 0], [5, 4, 3, 4], []],
	[[5, 1, 5, 1], [2, 4, 0, 1], [0, 3, 2, 3], [0, 1, 5, 4], [3, 0, 2, 3], [2, 4, 5, 4], []],
	[[3, 1, 2, 5], [2, 0, 4, 0], [3, 5, 3, 1], [0, 2, 4, 0], [4, 1, 4, 1], [3, 5, 2, 5], []],
	[[3, 1, 5, 1], [4, 0, 4, 2], [1, 3, 5, 1], [4, 2, 5, 2], [4, 0, 3, 0], [5, 2, 3, 0], []],
	[[0, 5, 2, 0], [5, 0, 2, 0], [2, 1, 5, 4], [3, 4, 3, 1], [2, 1, 3, 1], [5, 4, 3, 4], []],
	[[0, 2, 0, 4], [3, 5, 1, 2], [1, 4, 1, 4], [0, 2, 1, 2], [0, 4, 5, 3], [5, 3, 5, 3], []],
	[[4, 0, 1, 3], [2, 5, 1, 5], [2, 3, 1, 3], [1, 5, 0, 4], [0, 4, 0, 4], [2, 3, 2, 5], []],
	[[3, 0, 2, 0], [3, 4, 2, 5], [3, 0, 1, 4], [1, 5, 2, 5], [1, 4, 2, 0], [5, 1, 3, 4], []],
	[[5, 0, 4, 1], [5, 2, 3, 4], [3, 1, 4, 1], [3, 4, 0, 2], [1, 3, 5, 0], [5, 2, 0, 2], []],
	[[4, 1, 5, 3], [4, 2, 4, 1], [0, 3, 5, 3], [0, 1, 5, 2], [0, 3, 0, 1], [4, 2, 5, 2], []],
	[[1, 4, 0, 4], [0, 2, 0, 2], [1, 4, 5, 3], [5, 3, 5, 3], [1, 2, 0, 4], [3, 5, 1, 2], []],
	[[0, 4, 0, 4], [2, 3, 1, 3], [4, 0, 2, 5], [2, 5, 1, 5], [1, 5, 1, 3], [2, 3, 0, 4], []],
	[[3, 1, 5, 1], [4, 0, 4, 2], [1, 3, 2, 5], [4, 2, 5, 1], [4, 0, 3, 0], [5, 2, 3, 0], []],
	[[4, 0, 5, 1], [2, 5, 1, 3], [2, 3, 1, 3], [1, 5, 0, 4], [0, 4, 0, 4], [2, 3, 2, 5], []],
	[[3, 0, 2, 0], [1, 4, 2, 5], [3, 0, 1, 4], [1, 5, 2, 5], [3, 4, 2, 0], [5, 1, 3, 4], []],
	[[3, 0, 4, 1], [5, 2, 3, 0], [3, 1, 4, 1], [5, 4, 0, 2], [1, 3, 5, 4], [5, 2, 0, 2], []],
	[[3, 1, 5, 1], [4, 0, 4, 2], [1, 3, 5, 2], [4, 2, 5, 1], [4, 0, 3, 0], [5, 2, 3, 0], []],
	[[3, 1, 2, 5], [2, 0, 4, 0], [3, 5, 3, 1], [0, 2, 4, 1], [4, 1, 4, 0], [3, 5, 2, 5], []],
	[[0, 2, 0, 4], [3, 5, 1, 4], [1, 4, 1, 2], [0, 2, 1, 2], [0, 4, 5, 3], [5, 3, 5, 3], []],
	[[4, 0, 1, 5], [2, 5, 1, 3], [2, 3, 1, 3], [1, 5, 0, 4], [0, 4, 0, 4], [2, 3, 2, 5], []],
	[[0, 1, 5, 3], [4, 2, 4, 1], [0, 3, 5, 3], [4, 1, 5, 2], [0, 3, 0, 1], [4, 2, 5, 2], []],
	[[3, 1, 2, 5], [2, 0, 4, 0], [3, 5, 3, 1], [0, 2, 1, 4], [4, 1, 4, 0], [3, 5, 2, 5], []],
]

var level_index: int = 0
var tubes: Array = [] ## Array of Array[int]
var selected: int = -1
var history: Array = [] ## snapshots of tubes
var won: bool = false
var lost: bool = false
var combo: int = 0
var combo_peak: int = 0
var session_clears: int = 0
var time_left: float = LEVEL_TIME
var _pour_busy: bool = false
var _extra_well_used: bool = false
var _last_pour_n: int = 0
var _last_pour_color: int = 0
var _chips_shown: int = 0
var _chips_tween: Tween
var _crowd_reacting: bool = false
var _crowd_base_top: Array[float] = []
var _crowd_base_bot: Array[float] = []

var _logo: Control
var _level_label: Label
var _time_label: Label
var _chips_label: Label
var _chips_num: Label
var _clears_label: Label
var _status: Label
var _tube_row: HBoxContainer
var _win_overlay: WinOverlay
var _lose_panel: Control
var _lose_label: Label
var _lose_flavor: Label
var _shop_panel: Control
var _shop_toast: Label
var _shop_sheet_toast: Label
var _shop_toast_tween: Tween
var _tube_views: Array = []
var _flash: ColorRect
var _top_wash: ColorRect
var _bottom_wash: ColorRect
var _level_tile: Control
var _time_tile: Control
var _clears_tile: Control
var _clear_pips: Array = []
var _sfx_pick: AudioStreamPlayer
var _sfx_pour: AudioStreamPlayer
var _sfx_invalid: AudioStreamPlayer
var _sfx_clear: AudioStreamPlayer
var _sfx_undo: AudioStreamPlayer
var _sfx_restart: AudioStreamPlayer
var _sfx_next: AudioStreamPlayer
var _sfx_combo: AudioStreamPlayer
var _sfx_cheer_match: AudioStreamPlayer
var _sfx_cheer_clear: AudioStreamPlayer
var _sfx_lose: AudioStreamPlayer
var _bgm: AudioStreamPlayer
var _bgm_tween: Tween
var _crowd_faces: Array[TextureRect] = []
var _crowd_watch_tex: Texture2D
var _crowd_cheer_tex: Texture2D
var _crowd_groan_tex: Texture2D
var _crowd_tween: Tween
var _hint_pulse: Tween
var _hint_poured: bool = false
var _hint_art: TextureRect
var _session_live: bool = false
var _shop_btn: Button
var _restart_btn: Button
var _undo_btn: Button
var _chips_panel: Control
var _play_host: Control
var _title_catcher: Control
var _title_prompt: Control
var _title_pulse: Tween
var _title_streak: Label
var _live_hud: Array[CanvasItem] = []
var _progress: TintProgress

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_progress = TintProgressScript.new()
	_progress.boot(LEVELS.size())
	session_clears = _progress.current_pack_clears
	_build_ui()
	_load_level(_progress.campaign_level_index)
	_show_title()
	if OS.get_environment("TINT_DROP_CAPTURE") != "":
		_run_overlay_capture()
	elif OS.get_environment("TINT_DROP_SHOP_CAPTURE") != "":
		_run_shop_capture()

func _process(delta: float) -> void:
	if _bgm != null and _bgm.stream != null and not _bgm.playing:
		_bgm.play()
	_bob_crowd()
	if _session_live and not won and not lost:
		time_left = maxf(time_left - delta, 0.0)
		if time_left <= 0.0:
			_on_timeout()
	_update_timer_hud()

func _build_ui() -> void:
	_build_background()
	_setup_sfx()

	_logo = LogoMarkScript.new()
	_logo.position = Vector2(80, 16)
	_logo.custom_minimum_size = Vector2(560, 240)
	_logo.size = Vector2(560, 240)
	add_child(_logo)
	_logo.custom_minimum_size = Vector2(560, 240)
	_logo.size = Vector2(560, 240)
	_logo.pivot_offset = Vector2(280, 120)

	_chips_panel = _glass_panel(Vector2(24, 272), Vector2(672, 100), TEX_BOARD_HERO)
	add_child(_chips_panel)
	var chips_col := VBoxContainer.new()
	chips_col.set_anchors_preset(PRESET_FULL_RECT)
	chips_col.offset_left = 0.0
	chips_col.offset_top = 0.0
	chips_col.offset_right = 0.0
	chips_col.offset_bottom = 0.0
	chips_col.alignment = BoxContainer.ALIGNMENT_CENTER
	chips_col.add_theme_constant_override("separation", 0)
	_chips_panel.add_child(chips_col)
	_chips_num = Label.new()
	_chips_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chips_num.add_theme_font_size_override("font_size", 64)
	_chips_num.add_theme_color_override("font_color", UI_HERO)
	_chips_num.text = "0"
	chips_col.add_child(_chips_num)
	var chips_cap := Label.new()
	chips_cap.text = "to sort"
	chips_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chips_cap.add_theme_font_size_override("font_size", 14)
	chips_cap.add_theme_color_override("font_color", UI_CAPTION)
	chips_col.add_child(chips_cap)
	_chips_label = _chips_num

	_time_tile = _glass_panel(Vector2(24, 384), Vector2(216, 80), TEX_BOARD_TILE)
	add_child(_time_tile)
	_time_label = _tile_value(_time_tile, "TIME", "60")
	_time_label.pivot_offset = Vector2(108.0, 40.0)

	_level_tile = _glass_panel(Vector2(252, 384), Vector2(216, 80), TEX_BOARD_TILE)
	add_child(_level_tile)
	_level_label = _tile_value(_level_tile, "LEVEL", "1/10")

	_clears_tile = _glass_panel(Vector2(480, 384), Vector2(216, 80), TEX_BOARD_TILE)
	add_child(_clears_tile)
	var clears_col := VBoxContainer.new()
	clears_col.set_anchors_preset(PRESET_FULL_RECT)
	clears_col.offset_left = 0.0
	clears_col.offset_top = 0.0
	clears_col.offset_right = 0.0
	clears_col.offset_bottom = 0.0
	clears_col.alignment = BoxContainer.ALIGNMENT_CENTER
	clears_col.add_theme_constant_override("separation", 4)
	_clears_tile.add_child(clears_col)
	var clears_cap := Label.new()
	clears_cap.text = "CLEARS"
	clears_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clears_cap.add_theme_font_size_override("font_size", 14)
	clears_cap.add_theme_color_override("font_color", UI_CAPTION)
	clears_col.add_child(clears_cap)
	var pip_row := HBoxContainer.new()
	pip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pip_row.add_theme_constant_override("separation", 12)
	clears_col.add_child(pip_row)
	_clear_pips.clear()
	for _i in PACK_CLEARS:
		var pip := TextureRect.new()
		pip.texture = TEX_PIP_EMPTY
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.custom_minimum_size = Vector2(20, 20)
		pip.size = Vector2(20, 20)
		pip.pivot_offset = Vector2(10, 10)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pip_row.add_child(pip)
		_clear_pips.append(pip)
	_clears_label = Label.new()
	_clears_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clears_label.add_theme_font_size_override("font_size", 16)
	_clears_label.add_theme_color_override("font_color", UI_NUM)
	clears_col.add_child(_clears_label)
	_refresh_clears_label()

	_restart_btn = _make_btn("Restart", _on_restart, Vector2(24, 496))
	add_child(_restart_btn)
	_undo_btn = _make_btn("Undo", _on_undo, Vector2(252, 496))
	add_child(_undo_btn)
	_shop_btn = _make_btn("Shop", _on_shop, Vector2(480, 496))
	add_child(_shop_btn)

	_shop_toast = Label.new()
	_shop_toast.position = Vector2(480, 548)
	_shop_toast.size = Vector2(216, 16)
	_shop_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_toast.add_theme_font_size_override("font_size", 14)
	_shop_toast.add_theme_color_override("font_color", UI_CAPTION)
	_shop_toast.text = ""
	add_child(_shop_toast)

	_play_host = CenterContainer.new()
	_play_host.position = Vector2(0, 756)
	_play_host.size = Vector2(720, 300)
	add_child(_play_host)

	_tube_row = HBoxContainer.new()
	_tube_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tube_row.add_theme_constant_override("separation", 12)
	_play_host.add_child(_tube_row)

	_hint_art = TextureRect.new()
	_hint_art.texture = TEX_HINT_TAP
	_hint_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hint_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hint_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_art.anchor_left = 0.5
	_hint_art.anchor_top = 0.5
	_hint_art.anchor_right = 0.5
	_hint_art.anchor_bottom = 0.5
	_hint_art.offset_left = -300.0
	_hint_art.offset_top = -54.5
	_hint_art.offset_right = 300.0
	_hint_art.offset_bottom = 54.5
	_hint_art.pivot_offset = Vector2(300, 54.5)
	add_child(_hint_art)

	_status = Label.new()
	_status.anchor_left = 0.5
	_status.anchor_top = 0.5
	_status.anchor_right = 0.5
	_status.anchor_bottom = 0.5
	_status.offset_left = -300.0
	_status.offset_top = -40.0
	_status.offset_right = 300.0
	_status.offset_bottom = 40.0
	_status.size = Vector2(600, 80)
	_status.pivot_offset = Vector2(300, 40)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.text = ""
	_status.visible = false
	_status.add_theme_font_override("font", HINT_FONT)
	_status.add_theme_font_size_override("font_size", 38)
	_status.add_theme_color_override("font_color", Color8(243, 230, 216))
	_status.add_theme_color_override("font_outline_color", Color8(59, 30, 22))
	_status.add_theme_constant_override("outline_size", 4)
	_status.add_theme_color_override("font_shadow_color", Color8(59, 30, 22, 140))
	_status.add_theme_constant_override("shadow_offset_x", 2)
	_status.add_theme_constant_override("shadow_offset_y", 2)
	_status.add_theme_constant_override("shadow_outline_size", 0)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	_start_hint_pulse()

	_flash = ColorRect.new()
	_flash.color = Color(0.82, 1.0, 0.96, 0.0)
	_flash.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_win_overlay = WinOverlayScript.new()
	add_child(_win_overlay)
	_win_overlay.next_pressed.connect(_on_next)
	_win_overlay.fanfare_ended.connect(_restore_bgm)

	_lose_panel = Control.new()
	_lose_panel.visible = false
	_lose_panel.position = Vector2(120, 480)
	_lose_panel.size = Vector2(480, 320)
	_lose_panel.custom_minimum_size = Vector2(480, 320)
	_lose_panel.pivot_offset = Vector2(240, 160)
	_lose_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_lose_panel.clip_contents = false
	_add_walnut_icing(_lose_panel)
	_lose_panel.add_child(_plaque_tex(TEX_BOARD_HERO))
	add_child(_lose_panel)

	var lose_col := VBoxContainer.new()
	lose_col.add_theme_constant_override("separation", 10)
	_fill_rect(lose_col)
	lose_col.offset_left = 36.0
	lose_col.offset_right = -36.0
	lose_col.offset_top = 28.0
	lose_col.offset_bottom = -28.0
	lose_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_lose_panel.add_child(lose_col)
	_lose_label = Label.new()
	_lose_label.text = "Time's up."
	_lose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lose_label.add_theme_font_size_override("font_size", 32)
	_lose_label.add_theme_color_override("font_color", UI_CAPTION)
	lose_col.add_child(_lose_label)
	_lose_flavor = Label.new()
	_lose_flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lose_flavor.add_theme_font_size_override("font_size", 16)
	_lose_flavor.add_theme_color_override("font_color", UI_CAPTION)
	_lose_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lose_flavor.text = "Retry's free."
	lose_col.add_child(_lose_flavor)
	var lose_retry := _make_btn("Retry", _on_restart)
	lose_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lose_col.add_child(lose_retry)

	_build_shop_panel()
	_build_title_catcher()
	_collect_live_hud()
	if _shop_btn != null:
		move_child(_shop_btn, get_child_count() - 1)
	if _shop_panel != null:
		move_child(_shop_panel, get_child_count() - 1)

func _plaque_tex(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(tr)
	return tr

func _add_walnut_icing(host: Control) -> void:
	var pan := Panel.new()
	pan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(pan)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI_FILL
	sb.border_color = UI_RIM
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	pan.add_theme_stylebox_override("panel", sb)
	host.add_child(pan)

func _glass_panel(pos: Vector2, sz: Vector2, tex: Texture2D = TEX_BOARD_TILE) -> Control:
	var pan := Control.new()
	pan.position = pos
	pan.size = sz
	pan.custom_minimum_size = sz
	pan.pivot_offset = sz * 0.5
	pan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pan.clip_contents = false
	var tr := _plaque_tex(tex)
	pan.add_child(tr)
	return pan

func _tile_value(panel: Control, caption: String, initial: String) -> Label:
	var col := VBoxContainer.new()
	col.set_anchors_preset(PRESET_FULL_RECT)
	col.offset_left = 0.0
	col.offset_top = 0.0
	col.offset_right = 0.0
	col.offset_bottom = 0.0
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	var cap := Label.new()
	cap.text = caption
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 14)
	cap.add_theme_color_override("font_color", UI_CAPTION)
	col.add_child(cap)
	var lab := Label.new()
	lab.text = initial
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 36)
	lab.add_theme_color_override("font_color", UI_NUM)
	col.add_child(lab)
	return lab

func _fill_rect(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0

func _start_hint_pulse() -> void:
	if _hint_art == null:
		return
	if _hint_pulse != null and is_instance_valid(_hint_pulse):
		_hint_pulse.kill()
	_hint_art.pivot_offset = Vector2(300, 54.5)
	_hint_art.scale = Vector2.ONE
	_hint_pulse = create_tween()
	_hint_pulse.set_loops()
	_hint_pulse.tween_property(_hint_art, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hint_pulse.tween_property(_hint_art, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _build_title_catcher() -> void:
	_title_catcher = Control.new()
	_title_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_fill_rect(_title_catcher)
	_title_catcher.gui_input.connect(_on_title_gui_input)
	add_child(_title_catcher)

	_title_prompt = Control.new()
	_title_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_prompt.anchor_left = 0.5
	_title_prompt.anchor_top = 0.5
	_title_prompt.anchor_right = 0.5
	_title_prompt.anchor_bottom = 0.5
	_title_prompt.offset_left = -280.0
	_title_prompt.offset_top = -68.0
	_title_prompt.offset_right = 280.0
	_title_prompt.offset_bottom = 68.0
	_title_prompt.custom_minimum_size = Vector2(560.0, 136.0)
	_title_prompt.pivot_offset = Vector2(280.0, 68.0)
	_title_catcher.add_child(_title_prompt)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	_fill_rect(col)
	_title_prompt.add_child(col)

	var tap := Label.new()
	tap.text = "TAP TO PLAY"
	tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tap.add_theme_font_override("font", HINT_FONT)
	tap.add_theme_font_size_override("font_size", 42)
	tap.add_theme_color_override("font_color", UI_CAPTION)
	tap.add_theme_color_override("font_outline_color", UI_ESPRESSO)
	tap.add_theme_constant_override("outline_size", 4)
	tap.add_theme_color_override("font_shadow_color", Color8(59, 30, 22, 140))
	tap.add_theme_constant_override("shadow_offset_x", 2)
	tap.add_theme_constant_override("shadow_offset_y", 2)
	col.add_child(tap)

	var cap := Label.new()
	cap.text = "90s · 5 clears"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_theme_font_override("font", HINT_FONT)
	cap.add_theme_font_size_override("font_size", 16)
	cap.add_theme_color_override("font_color", UI_CAPTION)
	cap.add_theme_color_override("font_outline_color", UI_ESPRESSO)
	cap.add_theme_constant_override("outline_size", 2)
	col.add_child(cap)

	_title_streak = Label.new()
	_title_streak.text = ""
	_title_streak.visible = false
	_title_streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_streak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_streak.add_theme_font_override("font", HINT_FONT)
	_title_streak.add_theme_font_size_override("font_size", 16)
	_title_streak.add_theme_color_override("font_color", UI_CAPTION)
	_title_streak.add_theme_color_override("font_outline_color", UI_ESPRESSO)
	_title_streak.add_theme_constant_override("outline_size", 2)
	col.add_child(_title_streak)
	_refresh_title_streak()


func _start_title_pulse() -> void:
	if _title_prompt == null:
		return
	if _title_pulse != null and is_instance_valid(_title_pulse):
		_title_pulse.kill()
	_title_prompt.pivot_offset = Vector2(280.0, 68.0)
	_title_prompt.scale = Vector2.ONE
	_title_pulse = create_tween()
	_title_pulse.set_loops()
	_title_pulse.tween_property(_title_prompt, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_pulse.tween_property(_title_prompt, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _refresh_title_streak() -> void:
	if _title_streak == null:
		return
	if _progress != null and _progress.should_show_streak_chip():
		_title_streak.text = _progress.streak_chip_text()
		_title_streak.visible = true
	else:
		_title_streak.text = ""
		_title_streak.visible = false


func _show_title() -> void:
	_session_live = false
	_dismiss_win_overlay()
	_restore_bgm()
	if _title_catcher != null:
		_title_catcher.visible = true
		_title_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	if _tube_row != null:
		_tube_row.visible = false
	_set_hint_visible(false)
	if _status != null:
		_status.visible = false
	time_left = _level_clock()
	_update_timer_hud()
	_refresh_title_streak()
	_start_title_pulse()


func _begin_session() -> void:
	if _session_live:
		return
	_session_live = true
	if _title_catcher != null:
		_title_catcher.visible = false
		_title_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _title_pulse != null and is_instance_valid(_title_pulse):
		_title_pulse.kill()
		_title_pulse = null
	if _title_prompt != null:
		_title_prompt.scale = Vector2.ONE
	if _tube_row != null:
		_tube_row.visible = true
	time_left = _level_clock()
	_set_hint_visible(true)
	_play_sfx(_sfx_next)


func _on_title_gui_input(event: InputEvent) -> void:
	if _session_live:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		_begin_session()
		_title_catcher.accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if not st.pressed:
			return
		_begin_session()
		_title_catcher.accept_event()


func _set_hint_visible(show: bool) -> void:
	if _hint_art == null:
		return
	if show and not _hint_poured and not won and not lost:
		_hint_art.visible = true
		_hint_art.modulate = Color(1, 1, 1, 1)
		if _status != null:
			_status.visible = false
		_start_hint_pulse()
	else:
		_hint_art.visible = false
		_hint_art.modulate = Color(1, 1, 1, 0)
		if _hint_pulse != null and is_instance_valid(_hint_pulse):
			_hint_pulse.kill()
			_hint_pulse = null
		_hint_art.scale = Vector2.ONE

func _show_status(msg: String) -> void:
	if _status == null:
		return
	_status.text = msg
	_status.visible = true
	_status.modulate = Color(1, 1, 1, 1)
	if _hint_art != null:
		_hint_art.visible = false
		if _hint_pulse != null and is_instance_valid(_hint_pulse):
			_hint_pulse.kill()
			_hint_pulse = null
		_hint_art.scale = Vector2.ONE

func _build_background() -> void:
	var fallback := ColorRect.new()
	fallback.color = Color(0.07, 0.09, 0.16)
	_fill_rect(fallback)
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)

	var cafe := TextureRect.new()
	cafe.texture = CAFE_BG
	cafe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cafe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cafe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(cafe)
	add_child(cafe)

	_top_wash = ColorRect.new()
	_top_wash.color = Color(0.05, 0.06, 0.10, 0.18)
	_top_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(_top_wash)
	_top_wash.anchor_bottom = 0.0
	_top_wash.offset_bottom = 140.0
	add_child(_top_wash)

	_bottom_wash = ColorRect.new()
	_bottom_wash.color = Color(0.04, 0.05, 0.08, 0.38)
	_bottom_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill_rect(_bottom_wash)
	_bottom_wash.anchor_top = 1.0
	_bottom_wash.offset_top = -260.0
	add_child(_bottom_wash)

	_build_crowd()
	_apply_pack_tint()


func _build_crowd() -> void:
	_crowd_faces.clear()
	_crowd_base_top.clear()
	_crowd_base_bot.clear()
	_crowd_watch_tex = TEX_TABLE_WATCH
	_crowd_cheer_tex = TEX_TABLE_CHEER
	if ResourceLoader.exists(TEX_TABLE_GROAN_PATH):
		_crowd_groan_tex = load(TEX_TABLE_GROAN_PATH)
	else:
		_crowd_groan_tex = TEX_TABLE_WATCH
	var face := TextureRect.new()
	face.texture = _crowd_watch_tex
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.anchor_left = 0.08
	face.anchor_right = 0.92
	face.anchor_top = 1.0
	face.anchor_bottom = 1.0
	face.offset_left = 0.0
	face.offset_right = 0.0
	face.offset_top = -220.0
	face.offset_bottom = 0.0
	face.pivot_offset = Vector2(302.0, 220.0)
	face.scale = Vector2.ONE
	add_child(face)
	_crowd_faces.append(face)
	_crowd_base_top.append(face.offset_top)
	_crowd_base_bot.append(face.offset_bottom)
	_set_crowd_col(CROWD_WATCH)


func _apply_pack_tint() -> void:
	var pack: int = int(session_clears / PACK_CLEARS) % 3
	var tops: Array[Color] = [
		Color(0.05, 0.06, 0.10, 0.18),
		Color(0.10, 0.06, 0.04, 0.18),
		Color(0.04, 0.07, 0.11, 0.18),
	]
	var bots: Array[Color] = [
		Color(0.04, 0.05, 0.08, 0.38),
		Color(0.08, 0.04, 0.03, 0.38),
		Color(0.03, 0.05, 0.09, 0.40),
	]
	if _top_wash != null:
		_top_wash.color = tops[pack]
	if _bottom_wash != null:
		_bottom_wash.color = bots[pack]


func _set_crowd_col(col: int) -> void:
	for i in _crowd_faces.size():
		_set_crowd_face_col(i, col)


func _set_crowd_face_col(face_i: int, col: int) -> void:
	if face_i < 0 or face_i >= _crowd_faces.size():
		return
	var c: int = clampi(col, 0, 2)
	var tex: Texture2D = _crowd_watch_tex
	if c == CROWD_CHEER:
		tex = _crowd_cheer_tex
	elif c == CROWD_GROAN:
		tex = _crowd_groan_tex
	_crowd_faces[face_i].texture = tex


func _crowd_react(cheer: bool) -> void:
	if _crowd_faces.is_empty():
		return
	if _crowd_tween != null:
		_crowd_tween.kill()
	_crowd_reacting = true
	_reset_crowd_bob()
	_set_crowd_col(CROWD_WATCH)
	for face in _crowd_faces:
		if is_instance_valid(face):
			face.scale = Vector2.ONE
	var pose: int = CROWD_CHEER if cheer else CROWD_GROAN
	var hold: float = 0.55 if cheer else 0.45
	_crowd_tween = create_tween()
	_crowd_tween.set_parallel(true)
	for i in _crowd_faces.size():
		var delay: float = float(i) * 0.06
		var face: TextureRect = _crowd_faces[i]
		_crowd_tween.tween_callback(_set_crowd_face_col.bind(i, pose)).set_delay(delay)
		_crowd_tween.tween_callback(_set_crowd_face_col.bind(i, CROWD_WATCH)).set_delay(delay + hold)
		if cheer and is_instance_valid(face):
			_crowd_tween.tween_property(face, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
			_crowd_tween.tween_property(face, "scale", Vector2.ONE, 0.18).set_delay(delay + 0.12)
	_crowd_tween.chain().tween_callback(func() -> void:
		_crowd_reacting = false
	)


func _reset_crowd_bob() -> void:
	for i in _crowd_faces.size():
		var face: TextureRect = _crowd_faces[i]
		if is_instance_valid(face) and i < _crowd_base_top.size():
			face.offset_top = _crowd_base_top[i]
			face.offset_bottom = _crowd_base_bot[i]


func _bob_crowd() -> void:
	if _crowd_reacting or _crowd_faces.is_empty():
		return
	var t: float = Time.get_ticks_msec() * 0.001
	for i in _crowd_faces.size():
		var face: TextureRect = _crowd_faces[i]
		if not is_instance_valid(face):
			continue
		var bob: float = sin(t * 1.35 + float(i) * 0.85) * 4.0
		face.offset_top = _crowd_base_top[i] + bob
		face.offset_bottom = _crowd_base_bot[i] + bob

func _setup_sfx() -> void:
	_sfx_pick = _make_sfx(SFX_PICK)
	_sfx_pour = _make_sfx(SFX_POUR)
	_sfx_invalid = _make_sfx(SFX_INVALID)
	_sfx_clear = _make_sfx(SFX_CLEAR)
	_sfx_undo = _make_sfx(SFX_UNDO)
	_sfx_restart = _make_sfx(SFX_RESTART)
	_sfx_next = _make_sfx(SFX_NEXT)
	_sfx_combo = _make_sfx(SFX_COMBO)
	_sfx_cheer_match = _make_sfx(SFX_CHEER_MATCH)
	_sfx_cheer_clear = _make_sfx(SFX_CHEER_CLEAR)
	_sfx_lose = _make_sfx(SFX_LOSE)
	_bgm = AudioStreamPlayer.new()
	var bgm_stream: AudioStream = BGM_PLAY
	if bgm_stream is AudioStreamWAV:
		var wav := bgm_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var bytes_per_frame: int = 2
		if wav.stereo:
			bytes_per_frame = 4
		var frames: int = 0
		if bytes_per_frame > 0:
			frames = int(wav.data.size() / bytes_per_frame)
		wav.loop_end = frames
	_bgm.stream = bgm_stream
	_bgm.bus = "Master"
	_bgm.volume_db = BGM_VOL
	_bgm.autoplay = false
	add_child(_bgm)
	_bgm.play()

func _duck_bgm() -> void:
	if _bgm == null:
		return
	if _bgm_tween != null and is_instance_valid(_bgm_tween):
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", BGM_DUCK, 0.10)
	_bgm_tween.tween_property(_bgm, "volume_db", BGM_VOL, 0.55)


func _hold_bgm_duck() -> void:
	if _bgm == null:
		return
	if _bgm_tween != null and is_instance_valid(_bgm_tween):
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", BGM_DUCK, 0.12)


func _restore_bgm() -> void:
	if _bgm == null:
		return
	if _bgm_tween != null and is_instance_valid(_bgm_tween):
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm, "volume_db", BGM_VOL, 0.35)


func _collect_live_hud() -> void:
	_live_hud.clear()
	var nodes: Array = [
		_logo, _chips_panel, _time_tile, _level_tile, _clears_tile,
		_restart_btn, _undo_btn, _shop_btn, _shop_toast, _play_host, _hint_art, _status,
		_top_wash, _bottom_wash, _flash,
	]
	for n in nodes:
		if n is CanvasItem:
			_live_hud.append(n as CanvasItem)
	for face in _crowd_faces:
		if is_instance_valid(face):
			_live_hud.append(face)


func _set_live_play_visible(show: bool) -> void:
	for n in _live_hud:
		if is_instance_valid(n):
			n.visible = show
	if not show:
		if _shop_panel != null:
			_shop_panel.visible = false
		if _lose_panel != null:
			_lose_panel.visible = false
	if show and _tube_row != null:
		_tube_row.visible = _session_live
	if show:
		_set_hint_visible(_session_live and not _hint_poured and not won and not lost)


func _dismiss_win_overlay() -> void:
	if _win_overlay != null:
		_win_overlay.dismiss()
	_set_live_play_visible(true)


func _run_overlay_capture() -> void:
	var kind: String = OS.get_environment("TINT_DROP_CAPTURE")
	var out_path: String = OS.get_environment("TINT_DROP_CAPTURE_PATH")
	if out_path.is_empty():
		out_path = "/tmp/win_overlay_%s.png" % kind
	_session_live = true
	if _title_catcher != null:
		_title_catcher.visible = false
		_title_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	await get_tree().process_frame
	var pack_done: bool = kind == "pack"
	var filled: int = 5 if pack_done else 3
	_set_live_play_visible(false)
	if _win_overlay != null:
		_win_overlay.present(pack_done, false, filled)
	# Default snap is post-fanfare idle (hue spray on). Celebrate is the
	# 7s window before _enter_idle; used to prove spray is not on yet.
	var phase: String = OS.get_environment("TINT_DROP_CAPTURE_PHASE")
	if phase == "celebrate":
		await get_tree().create_timer(0.40).timeout
	else:
		await get_tree().create_timer(WinOverlay.FANFARE_S + 0.45).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			img.save_png(out_path)
	get_tree().quit()


func _run_shop_capture() -> void:
	var out_path: String = OS.get_environment("TINT_DROP_SHOP_CAPTURE")
	if out_path.is_empty():
		out_path = "/tmp/shop_sheet.png"
	_session_live = true
	if _title_catcher != null:
		_title_catcher.visible = false
		_title_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	await get_tree().process_frame
	_set_live_play_visible(true)
	_on_shop()
	await get_tree().process_frame
	await get_tree().process_frame
	var tap_sku: String = OS.get_environment("TINT_DROP_SHOP_TAP")
	if not tap_sku.is_empty():
		_on_shop_sku(tap_sku)
		await get_tree().process_frame
		await get_tree().process_frame
	var tex: ViewportTexture = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			img.save_png(out_path)
	get_tree().quit()


func _make_sfx(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Master"
	add_child(p)
	return p

func _play_sfx(p: AudioStreamPlayer) -> void:
	if p == null or p.stream == null:
		return
	p.stop()
	p.play()

func _play_pour_sfx() -> void:
	if _sfx_pour == null:
		return
	var steps: int = mini(combo - 1, 8)
	_sfx_pour.pitch_scale = 1.0 + float(steps) * 0.07
	_play_sfx(_sfx_pour)
	_play_sfx(_sfx_cheer_match)
	if combo >= 3:
		_sfx_combo.pitch_scale = 1.0 + float(mini(combo - 3, 5)) * 0.04
		_play_sfx(_sfx_combo)

func _reset_combo() -> void:
	combo = 0
	if _sfx_pour != null:
		_sfx_pour.pitch_scale = 1.0

func _btn_sb(inset: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(0)
	var pad: float = float(8 + inset)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	if inset > 0:
		sb.expand_margin_left = -float(inset)
		sb.expand_margin_right = -float(inset)
		sb.expand_margin_top = -float(inset)
		sb.expand_margin_bottom = -float(inset)
	return sb

func _pour_splash_color() -> Color:
	var pal: Array = TubeView.PALETTE
	if pal.is_empty():
		return UI_RIM
	var i: int = clampi(_last_pour_color, 0, pal.size() - 1)
	return pal[i]

func _btn_hue_splash(b: Button) -> void:
	if b == null or not is_instance_valid(b):
		return
	b.modulate = UI_HERO
	var tw: Tween = create_tween()
	tw.tween_property(b, "modulate", Color.WHITE, 0.12)

func _make_btn(text: String, cb: Callable, pos: Vector2 = Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(216, 72)
	b.custom_minimum_size = Vector2(216, 72)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", UI_CAPTION)
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	b.add_theme_color_override("font_pressed_color", UI_HERO)
	b.add_theme_color_override("font_focus_color", UI_CAPTION)
	var empty := _btn_sb(0)
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", _btn_sb(2))
	b.add_theme_stylebox_override("focus", empty)
	b.add_theme_stylebox_override("disabled", empty)
	var tr := _plaque_tex(TEX_BOARD_BTN)
	tr.show_behind_parent = true
	b.add_child(tr)
	b.button_down.connect(_btn_hue_splash.bind(b))
	b.pressed.connect(cb)
	return b

func _clone_state(src: Array) -> Array:
	var out: Array = []
	for t in src:
		var copy: Array[int] = []
		for c in t:
			copy.append(int(c))
		out.append(copy)
	return out

func _tube_complete(t: Array) -> bool:
	if t.size() != CAPACITY:
		return false
	var c: int = int(t[0])
	for x in t:
		if int(x) != c:
			return false
	return true

func _chips_left_count() -> int:
	var n: int = 0
	for t in tubes:
		if _tube_complete(t):
			continue
		n += t.size()
	return n

func _set_chips_label(n: int) -> void:
	if _chips_num != null:
		_chips_num.text = str(n)
	elif _chips_label != null:
		_chips_label.text = str(n)

func _sync_chips_left(animate: bool) -> void:
	var n: int = _chips_left_count()
	if not animate or _chips_label == null:
		_chips_shown = n
		if _chips_label != null:
			_set_chips_label(n)
		return
	if n == _chips_shown:
		_set_chips_label(n)
		return
	if _chips_tween != null and is_instance_valid(_chips_tween):
		_chips_tween.kill()
	var from_v: float = float(_chips_shown)
	var to_v: float = float(n)
	var steps: int = absi(n - _chips_shown)
	_chips_shown = n
	var dur: float = maxf(0.08, float(steps) * 0.08)
	_chips_tween = create_tween()
	_chips_tween.set_parallel(true)
	_chips_tween.tween_method(func(v: float) -> void:
		_set_chips_label(int(round(v)))
	, from_v, to_v, dur)
	if _chips_num != null:
		_chips_num.pivot_offset = _chips_num.size * 0.5
		_chips_num.scale = Vector2(1.12, 1.12)
		_chips_tween.tween_property(_chips_num, "scale", Vector2.ONE, 0.16)

func _refresh_clears_label() -> void:
	var filled: int = 0
	if _progress != null:
		filled = _progress.pack_pips_filled(won)
	else:
		var in_pack: int = session_clears % PACK_CLEARS
		filled = in_pack
		if won and in_pack == 0 and session_clears > 0:
			filled = PACK_CLEARS
	if _clears_label != null:
		_clears_label.text = "%d/%d" % [filled, PACK_CLEARS]
	for i in _clear_pips.size():
		var pip: TextureRect = _clear_pips[i]
		if not is_instance_valid(pip):
			continue
		var on: bool = i < filled
		var was: bool = pip.texture == TEX_PIP_LIT
		pip.texture = TEX_PIP_LIT if on else TEX_PIP_EMPTY
		if on and not was:
			pip.scale = Vector2(1.55, 1.55)
			var tw: Tween = create_tween()
			tw.tween_property(pip, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_punch_clears_tile()

func _update_timer_hud() -> void:
	if _time_label == null:
		return
	if not _session_live:
		_time_label.text = str(int(round(_level_clock())))
		_time_label.modulate = UI_NUM
		_time_label.scale = Vector2.ONE
		return
	var secs: int = int(ceil(time_left))
	_time_label.text = str(secs)
	if lost:
		_time_label.modulate = Color(1.0, 0.38, 0.34)
		_time_label.scale = Vector2.ONE
		return
	if won:
		_time_label.modulate = UI_NUM
		_time_label.scale = Vector2.ONE
		return
	var warn: float = 10.0
	if level_index >= PACK_CLEARS:
		warn = 12.0
	if time_left <= warn:
		var wave: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU)
		var pulse: float = lerpf(1.0, 1.12, wave)
		_time_label.scale = Vector2(pulse, pulse)
		_time_label.modulate = UI_HERO.lerp(UI_NUM, wave * 0.22)
	else:
		_time_label.modulate = UI_NUM
		_time_label.scale = Vector2.ONE

func _level_clock() -> float:
	var lv: int = level_index + 1
	if lv <= 1:
		return 90.0
	if lv == 2:
		return 75.0
	if lv <= 5:
		return 60.0
	if lv <= 8:
		return 50.0
	if lv <= 10:
		return 40.0
	return 35.0

func _tick_level_tile() -> void:
	if _level_tile == null:
		return
	_level_tile.pivot_offset = _level_tile.size * 0.5
	_level_tile.scale = Vector2(1.08, 1.08)
	var tw: Tween = create_tween()
	tw.tween_property(_level_tile, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _punch_clears_tile() -> void:
	if _clears_tile == null:
		return
	_clears_tile.pivot_offset = _clears_tile.size * 0.5
	_clears_tile.scale = Vector2(1.12, 1.12)
	var tw: Tween = create_tween()
	tw.tween_property(_clears_tile, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _punch_combo_hud(n: int) -> void:
	if _time_tile != null:
		_time_tile.pivot_offset = _time_tile.size * 0.5
		_time_tile.scale = Vector2(1.10, 1.10)
		var tw: Tween = create_tween()
		tw.tween_property(_time_tile, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if n >= 3 and _level_tile != null:
		_tick_level_tile()
	if _chips_num != null:
		_chips_num.pivot_offset = _chips_num.size * 0.5
		_chips_num.scale = Vector2(1.16, 1.16)
		var ct: Tween = create_tween()
		ct.tween_property(_chips_num, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _load_level(i: int) -> void:
	level_index = clampi(i, 0, LEVELS.size() - 1)
	tubes = _clone_state(LEVELS[level_index])
	selected = -1
	history.clear()
	won = false
	lost = false
	_pour_busy = false
	_extra_well_used = false
	time_left = _level_clock()
	combo_peak = 0
	_reset_combo()
	_dismiss_win_overlay()
	if _lose_panel != null:
		_lose_panel.visible = false
		_lose_panel.scale = Vector2.ONE
	if _shop_panel != null:
		_shop_panel.visible = false
	_level_label.text = "%d/%d" % [level_index + 1, LEVELS.size()]
	_tick_level_tile()
	_hint_poured = false
	if _status != null:
		_status.text = ""
		_status.visible = false
	_set_hint_visible(_session_live)
	if _tube_row != null:
		_tube_row.visible = _session_live
	_refresh_clears_label()
	_apply_pack_tint()
	_rebuild_tubes()
	_sync_chips_left(false)

func _tube_metrics(n: int) -> Vector2:
	n = maxi(n, 1)
	var sep: float = 8.0 if n >= 6 else 12.0
	var avail: float = 700.0
	var w: float = (avail - sep * float(n - 1)) / float(n)
	w = minf(w, TUBE_SCENE_W)
	w = maxf(w, 88.0)
	var h: float = w * (868.0 / 443.0)
	h = minf(h, TUBE_SCENE_H)
	w = h * (443.0 / 868.0)
	return Vector2(w, h)

func _rebuild_tubes() -> void:
	for child in _tube_row.get_children():
		child.queue_free()
	_tube_views.clear()
	var n: int = tubes.size()
	var metrics: Vector2 = _tube_metrics(n)
	_tube_row.add_theme_constant_override("separation", 8 if n >= 6 else 12)
	for i in n:
		var view: TubeView = TubeView.new()
		view.index = i
		view.custom_minimum_size = metrics
		view.size = metrics
		view.pivot_offset = metrics * 0.5
		view.set_chips(tubes[i])
		view.set_selected(i == selected)
		view.tapped.connect(_on_tube_tapped)
		_tube_row.add_child(view)
		_tube_views.append(view)

func _refresh_views() -> void:
	for i in _tube_views.size():
		var view: TubeView = _tube_views[i]
		if i < tubes.size():
			view.set_chips(tubes[i])
			view.set_selected(i == selected)

func _on_timeout() -> void:
	if won or lost:
		return
	lost = true
	selected = -1
	_pour_busy = false
	_reset_combo()
	_refresh_views()
	_set_hint_visible(false)
	if _status != null:
		_status.text = ""
		_status.visible = false
	if _lose_label != null:
		_lose_label.text = "Time's up."
	if _lose_flavor != null:
		_lose_flavor.text = "Retry's free."
	if _lose_panel != null:
		_lose_panel.visible = true
		_punch_lose()
	_play_sfx(_sfx_lose)
	_duck_bgm()
	_crowd_react(false)

func _on_tube_tapped(index: int) -> void:
	if not _session_live or won or lost or _pour_busy:
		return
	if index < 0 or index >= tubes.size():
		return
	if selected < 0:
		if tubes[index].is_empty():
			_show_status("Nothing to pick.")
			_play_sfx(_sfx_invalid)
			_crowd_react(false)
			return
		selected = index
		_show_status("Pour onto an empty tube or the same color.")
		_play_sfx(_sfx_pick)
		_refresh_views()
		return
	if selected == index:
		selected = -1
		_show_status("Cancelled.")
		_refresh_views()
		return
	var src_i: int = selected
	var dest_i: int = index
	var dest_before: Array = []
	for c in tubes[dest_i]:
		dest_before.append(int(c))
	if _try_pour(src_i, dest_i):
		selected = -1
		_hint_poured = true
		_set_hint_visible(false)
		combo += 1
		if combo > combo_peak:
			combo_peak = combo
		_play_pour_sfx()
		_crowd_react(true)
		_pour_busy = true
		if src_i < _tube_views.size():
			_tube_views[src_i].set_chips(tubes[src_i])
			_tube_views[src_i].set_selected(false)
			var dir_sign: float = 1.0
			if dest_i < _tube_views.size():
				var sxp: float = _tube_views[src_i].global_position.x
				var dxp: float = _tube_views[dest_i].global_position.x
				dir_sign = 1.0 if dxp >= sxp else -1.0
			_tube_views[src_i].play_pour_source(dir_sign)
		if dest_i < _tube_views.size():
			_tube_views[dest_i].set_chips(dest_before)
			_tube_views[dest_i].set_selected(false)
		var pour_col: Color = TubeView.PALETTE[clampi(_last_pour_color, 0, TubeView.PALETTE.size() - 1)]
		_spawn_pour_blobs(src_i, dest_i, _last_pour_n, pour_col, func() -> void:
			if dest_i < _tube_views.size() and dest_i < tubes.size():
				_tube_views[dest_i].set_chips(tubes[dest_i])
				_tube_views[dest_i].play_pour_dest()
			_sync_chips_left(true)
			_pour_busy = false
			var spark_col: Color = pour_col
			spark_col.a = 0.95
			var spark_n: int = 10 + mini(combo, 8) * 2
			_burst_at_tube(dest_i, spark_col, spark_n)
			if combo >= 2:
				_float_combo(dest_i, combo)
			if _is_won():
				_on_win()
		)
	else:
		_reset_combo()
		if dest_i < _tube_views.size():
			_tube_views[dest_i].flash_invalid()
		_play_sfx(_sfx_invalid)
		_crowd_react(false)
		_show_status("Can't pour — need empty or same color with space.")

func _spawn_pour_blobs(src_i: int, dest_i: int, n: int, col: Color, on_done: Callable) -> void:
	if n <= 0 or src_i >= _tube_views.size() or dest_i >= _tube_views.size():
		on_done.call()
		return
	var from: Vector2 = _tube_views[src_i].mouth_global_pos() - global_position
	var to: Vector2 = _tube_views[dest_i].mouth_global_pos() - global_position
	var mid: Vector2 = (from + to) * 0.5 + Vector2(0.0, -90.0)
	var last_i: int = n - 1
	for i in n:
		var blob := ColorRect.new()
		var sz: float = 14.0
		blob.color = col
		blob.size = Vector2(sz, sz)
		blob.pivot_offset = blob.size * 0.5
		blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blob.position = from - blob.size * 0.5
		add_child(blob)
		var delay: float = float(i) * 0.045
		var is_last: bool = i == last_i
		var tw: Tween = create_tween()
		tw.tween_interval(delay)
		tw.tween_method(_tick_blob.bind(blob, from, mid, to), 0.0, 1.0, 0.22)
		tw.tween_callback(_finish_blob.bind(blob, is_last, on_done))

func _tick_blob(blob: ColorRect, a: Vector2, b: Vector2, c: Vector2, t: float) -> void:
	if not is_instance_valid(blob):
		return
	var p: Vector2 = _bezier2(a, b, c, t)
	blob.position = p - blob.size * 0.5
	blob.rotation = t * 1.4

func _finish_blob(blob: ColorRect, is_last: bool, on_done: Callable) -> void:
	if is_instance_valid(blob):
		blob.queue_free()
	if is_last:
		on_done.call()

func _bezier2(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * a + 2.0 * u * t * b + t * t * c

func _float_combo(tube_i: int, n: int) -> void:
	if n < 2 or tube_i < 0 or tube_i >= _tube_views.size():
		return
	var at: Vector2 = _tube_views[tube_i].mouth_global_pos() - global_position + Vector2(-28.0, -36.0)
	var lab := Label.new()
	lab.text = "x%d" % n
	lab.add_theme_font_override("font", HINT_FONT)
	lab.add_theme_font_size_override("font_size", 44 + mini(n, 6) * 2)
	lab.add_theme_color_override("font_color", UI_HERO if n >= 3 else UI_CAPTION)
	lab.add_theme_color_override("font_outline_color", UI_ESPRESSO)
	lab.add_theme_constant_override("outline_size", 6)
	lab.position = at
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.pivot_offset = Vector2(36.0, 20.0)
	lab.scale = Vector2(0.72, 0.72)
	add_child(lab)
	var rise: float = 56.0 + float(mini(n, 6)) * 4.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lab, "position:y", at.y - rise, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "modulate:a", 0.0, 0.55).set_delay(0.12)
	tw.chain().tween_callback(lab.queue_free)
	_punch_combo_hud(n)

func _try_pour(src_i: int, dst_i: int) -> bool:
	var src: Array = tubes[src_i]
	var dst: Array = tubes[dst_i]
	if src.is_empty():
		return false
	if dst.size() >= CAPACITY:
		return false
	var color: int = src[src.size() - 1]
	if not dst.is_empty() and dst[dst.size() - 1] != color:
		return false
	var run := 0
	for k in range(src.size() - 1, -1, -1):
		if src[k] != color:
			break
		run += 1
	var space: int = CAPACITY - dst.size()
	var pour: int = mini(run, space)
	if pour <= 0:
		return false
	history.append(_clone_state(tubes))
	for _i in pour:
		dst.append(src.pop_back())
	_last_pour_n = pour
	_last_pour_color = color
	_show_status("Poured %d." % pour)
	return true

func _is_won() -> bool:
	for t in tubes:
		if t.is_empty():
			continue
		if t.size() != CAPACITY:
			return false
		var c: int = t[0]
		for x in t:
			if x != c:
				return false
	return true

func _on_win() -> void:
	won = true
	selected = -1
	_refresh_views()
	if _progress != null:
		_progress.record_clear(level_index, LEVELS.size())
	session_clears += 1
	_refresh_clears_label()
	_sync_chips_left(true)
	var pack_done: bool = false
	if _progress != null:
		pack_done = _progress.pack_just_completed()
	else:
		pack_done = (session_clears % PACK_CLEARS) == 0
	var campaign_done: bool = level_index >= LEVELS.size() - 1
	_set_hint_visible(false)
	if _win_overlay != null:
		var filled: int = session_clears % PACK_CLEARS
		if _progress != null:
			filled = _progress.pack_pips_filled(true)
		elif pack_done and session_clears > 0:
			filled = PACK_CLEARS
		_set_live_play_visible(false)
		_win_overlay.present(pack_done, campaign_done, filled)
	_play_sfx(_sfx_cheer_clear)
	_hold_bgm_duck()

func _bounce_full_tubes() -> void:
	var k: int = 0
	for i in tubes.size():
		if i >= _tube_views.size():
			continue
		var t: Array = tubes[i]
		if t.size() != CAPACITY:
			continue
		_tube_views[i].play_win_bounce(float(k) * 0.07)
		k += 1

func _punch_clear() -> void:
	if _flash != null:
		_flash.color = Color(0.78, 1.0, 0.94, 0.38)
		var ft: Tween = create_tween()
		ft.tween_property(_flash, "color:a", 0.0, 0.32)

func _punch_lose() -> void:
	if _flash != null:
		_flash.color = Color(0.18, 0.08, 0.08, 0.28)
		var ft: Tween = create_tween()
		ft.tween_property(_flash, "color:a", 0.0, 0.32)
	if _lose_panel == null:
		return
	_lose_panel.pivot_offset = Vector2(240.0, 160.0)
	_lose_panel.scale = Vector2(0.84, 0.84)
	var tw: Tween = create_tween()
	tw.tween_property(_lose_panel, "scale", Vector2(1.08, 1.08), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_lose_panel, "scale", Vector2.ONE, 0.12)

func _burst_at_tube(tube_i: int, col: Color, n: int) -> void:
	if tube_i < 0 or tube_i >= _tube_views.size():
		return
	var view: TubeView = _tube_views[tube_i]
	var local: Vector2 = view.get_global_rect().get_center() - global_position
	_spawn_sparks(local, col, n)

func _burst_at_center(col: Color, n: int) -> void:
	_spawn_sparks(size * 0.5, col, n)

func _spawn_sparks(at: Vector2, col: Color, n: int) -> void:
	for i in n:
		var spark := ColorRect.new()
		var sz: float = 5.0 + randf() * 7.0
		spark.color = col if i % 2 == 0 else col.lightened(0.25)
		spark.size = Vector2(sz, sz)
		spark.position = at - spark.size * 0.5
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.pivot_offset = spark.size * 0.5
		spark.rotation = randf() * TAU
		add_child(spark)
		var ang: float = (float(i) / float(n)) * TAU + randf() * 0.45
		var dist: float = 28.0 + randf() * 64.0
		if i % 3 == 0:
			dist *= 0.55
		var dest: Vector2 = at + Vector2(cos(ang), sin(ang)) * dist - spark.size * 0.5
		var life: float = 0.28 + randf() * 0.16
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(spark, "position", dest, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spark, "modulate:a", 0.0, life)
		tw.tween_property(spark, "scale", Vector2(0.2, 0.2), life)
		tw.tween_property(spark, "rotation", spark.rotation + 1.2, life)
		tw.chain().tween_callback(spark.queue_free)

func _on_restart() -> void:
	# Current board only. Does not rewind or advance campaign persist.
	if not _session_live:
		return
	_dismiss_win_overlay()
	_restore_bgm()
	if _lose_panel != null:
		_lose_panel.visible = false
	_play_sfx(_sfx_restart)
	_load_level(level_index)

func _on_undo() -> void:
	if not _session_live:
		return
	if won or lost or _pour_busy:
		return
	if history.is_empty():
		_show_status("Nothing to undo.")
		_play_sfx(_sfx_invalid)
		_crowd_react(false)
		return
	tubes = history.pop_back()
	selected = -1
	_reset_combo()
	_show_status("Undid last pour.")
	_play_sfx(_sfx_undo)
	_refresh_views()
	_sync_chips_left(true)

func _on_next() -> void:
	_dismiss_win_overlay()
	_restore_bgm()
	_play_sfx(_sfx_next)
	var campaign_done: bool = level_index >= LEVELS.size() - 1
	var next_i: int = level_index + 1
	if _progress != null:
		next_i = _progress.campaign_level_index
	if campaign_done:
		_session_live = false
		_load_level(next_i)
		_show_title()
	else:
		_load_level(next_i)

func _toast_shop(msg: String) -> void:
	if _shop_toast_tween != null and is_instance_valid(_shop_toast_tween):
		_shop_toast_tween.kill()
	if _shop_toast != null:
		_shop_toast.text = msg
	if _shop_sheet_toast != null:
		_shop_sheet_toast.text = msg
		_shop_sheet_toast.add_theme_color_override("font_color", UI_HERO)
	if _shop_toast == null and _shop_sheet_toast == null:
		return
	_shop_toast_tween = create_tween()
	_shop_toast_tween.tween_interval(1.8)
	_shop_toast_tween.tween_callback(func() -> void:
		if is_instance_valid(_shop_toast) and _shop_toast.text == msg:
			_shop_toast.text = ""
		if is_instance_valid(_shop_sheet_toast) and _shop_sheet_toast.text == msg:
			_shop_sheet_toast.text = SHOP_CAPTION
			_shop_sheet_toast.add_theme_color_override("font_color", UI_CAPTION)
	)

func _shop_flat(fill: Color, rim: Color, radius: int, border: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(border)
	sb.border_color = rim
	sb.set_corner_radius_all(radius)
	return sb

func _make_shop_row(sku_name: String, price: String, cb: Callable) -> Button:
	var sz := Vector2(600, 76)
	var b := Button.new()
	b.text = ""
	b.size = sz
	b.custom_minimum_size = sz
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", UI_CAPTION)
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	b.add_theme_color_override("font_pressed_color", UI_HERO)
	b.add_theme_color_override("font_focus_color", UI_CAPTION)
	var sb := _shop_flat(UI_BTN_FILL, UI_RIM, 12, 2)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", sb)
	var name_l := Label.new()
	name_l.text = sku_name
	name_l.position = Vector2(16, 8)
	name_l.size = Vector2(sz.x - 128, sz.y - 16)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 18)
	name_l.add_theme_color_override("font_color", UI_CAPTION)
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(name_l)
	var price_l := Label.new()
	price_l.text = price
	price_l.position = Vector2(sz.x - 112, 8)
	price_l.size = Vector2(96, sz.y - 16)
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_l.add_theme_font_size_override("font_size", 22)
	price_l.add_theme_color_override("font_color", UI_HERO)
	price_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(price_l)
	b.pressed.connect(cb)
	return b

func _build_shop_panel() -> void:
	_shop_panel = Control.new()
	_shop_panel.visible = false
	_shop_panel.position = Vector2(40, 160)
	_shop_panel.size = Vector2(640, 760)
	_shop_panel.custom_minimum_size = Vector2(640, 760)
	_shop_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_panel.clip_contents = false
	_add_walnut_icing(_shop_panel)
	_shop_panel.add_child(_plaque_tex(TEX_BOARD_HERO))
	add_child(_shop_panel)

	var title := Label.new()
	title.text = "Shop"
	title.position = Vector2(24, 16)
	title.size = Vector2(520, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UI_CAPTION)
	_shop_panel.add_child(title)

	var cap := Label.new()
	cap.text = SHOP_CAPTION
	cap.position = Vector2(24, 52)
	cap.size = Vector2(520, 28)
	cap.add_theme_font_size_override("font_size", 18)
	cap.add_theme_color_override("font_color", UI_CAPTION)
	_shop_panel.add_child(cap)
	_shop_sheet_toast = cap

	var close_b := Button.new()
	close_b.text = "X"
	close_b.position = Vector2(584, 8)
	close_b.size = Vector2(48, 48)
	close_b.custom_minimum_size = Vector2(48, 48)
	close_b.add_theme_font_size_override("font_size", 22)
	close_b.add_theme_color_override("font_color", UI_CAPTION)
	close_b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	close_b.add_theme_color_override("font_pressed_color", UI_HERO)
	close_b.add_theme_color_override("font_focus_color", UI_CAPTION)
	var close_sb := _shop_flat(UI_BTN_FILL, UI_RIM, 10, 2)
	close_b.add_theme_stylebox_override("normal", close_sb)
	close_b.add_theme_stylebox_override("hover", close_sb)
	close_b.add_theme_stylebox_override("pressed", close_sb)
	close_b.add_theme_stylebox_override("focus", close_sb)
	close_b.pressed.connect(_on_shop_close)
	_shop_panel.add_child(close_b)

	var list := VBoxContainer.new()
	list.position = Vector2(20, 88)
	list.size = Vector2(600, 620)
	list.add_theme_constant_override("separation", 8)
	_shop_panel.add_child(list)
	for row in SHOP_SKUS:
		var sku_name := String(row[0])
		var price := String(row[1])
		var sku_id := String(row[2])
		list.add_child(_make_shop_row(sku_name, price, _on_shop_sku.bind(sku_id)))

func _on_shop() -> void:
	if _shop_panel == null:
		return
	_shop_panel.visible = true
	move_child(_shop_panel, get_child_count() - 1)

func _on_shop_close() -> void:
	if _shop_panel != null:
		_shop_panel.visible = false

func _on_shop_sku(sku_id: String) -> void:
	print("IAP later")
	if sku_id == "extra_well":
		_apply_extra_well()
		return
	_toast_shop("Not billed yet.")

func _apply_extra_well() -> void:
	if _extra_well_used or won or lost:
		return
	_extra_well_used = true
	var extra: Array[int] = []
	tubes.append(extra)
	for snap in history:
		var e: Array[int] = []
		snap.append(e)
	selected = -1
	_rebuild_tubes()
	_sync_chips_left(false)
	if _shop_panel != null:
		_shop_panel.visible = false
	_show_status("Extra well.")
	_play_sfx(_sfx_pick)
