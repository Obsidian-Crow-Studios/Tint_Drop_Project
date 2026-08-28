extends RefCounted
class_name TintProgress

## Local campaign + daily pack + streak. Keep in sync with tools/progress_save.py.

const SAVE_PATH := "user://tint_drop.cfg"
const SECTION := "progress"
const PACK_CLEARS := 5
const CAMPAIGN_MAX := 99

var campaign_level_index: int = 0
var current_pack_clears: int = 0
var daily_pack_date: String = ""
var streak_days: int = 0
var last_play_date: String = ""
var save_path: String = SAVE_PATH
var level_count: int = 100


func boot(p_level_count: int, today: String = "") -> void:
	level_count = maxi(p_level_count, 1)
	if today.is_empty():
		today = local_today()
	var path: String = _effective_path()
	var had_save: bool = FileAccess.file_exists(path)
	load_from_disk()
	_clamp_fields()
	if had_save:
		apply_daily_rollover(today)
		save_to_disk()
	else:
		# First launch: do not create a file until a clear, so a look-then-quit
		# does not count as a play day.
		daily_pack_date = ""
		current_pack_clears = 0
		streak_days = 0
		last_play_date = ""
		campaign_level_index = 0


func local_today() -> String:
	var forced: String = OS.get_environment("TINT_DROP_TODAY")
	if not forced.is_empty():
		return forced
	var d: Dictionary = Time.get_date_dict_from_system()
	return format_ymd(int(d.year), int(d.month), int(d.day))


func format_ymd(year: int, month: int, day: int) -> String:
	return "%04d-%02d-%02d" % [year, month, day]


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(_effective_path())
	if err != OK:
		return
	campaign_level_index = int(cfg.get_value(SECTION, "campaign_level_index", 0))
	current_pack_clears = int(cfg.get_value(SECTION, "current_pack_clears", 0))
	daily_pack_date = str(cfg.get_value(SECTION, "daily_pack_date", ""))
	streak_days = int(cfg.get_value(SECTION, "streak_days", 0))
	last_play_date = str(cfg.get_value(SECTION, "last_play_date", ""))
	_clamp_fields()


func save_to_disk() -> void:
	_clamp_fields()
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "campaign_level_index", campaign_level_index)
	cfg.set_value(SECTION, "current_pack_clears", current_pack_clears)
	cfg.set_value(SECTION, "daily_pack_date", daily_pack_date)
	cfg.set_value(SECTION, "streak_days", streak_days)
	cfg.set_value(SECTION, "last_play_date", last_play_date)
	cfg.save(_effective_path())


func apply_daily_rollover(today: String) -> void:
	if today.is_empty() or daily_pack_date == today:
		return
	# New local date: tomorrow's pack. Streak uses last successful clear day.
	current_pack_clears = 0
	daily_pack_date = today
	if is_yesterday(last_play_date, today):
		streak_days = maxi(streak_days, 0) + 1
	else:
		streak_days = 1


func record_clear(cleared_index: int, p_level_count: int = -1, today: String = "") -> void:
	if p_level_count > 0:
		level_count = p_level_count
	if today.is_empty():
		today = local_today()
	var last_i: int = _last_index()
	var cleared: int = clampi(cleared_index, 0, last_i)
	if cleared >= last_i:
		campaign_level_index = 0
	else:
		campaign_level_index = cleared + 1
	if current_pack_clears >= PACK_CLEARS:
		current_pack_clears = 1
	else:
		current_pack_clears = clampi(current_pack_clears + 1, 0, PACK_CLEARS)
	daily_pack_date = today
	last_play_date = today
	if streak_days <= 0:
		streak_days = 1
	_clamp_fields()
	save_to_disk()


func pack_pips_filled(won: bool) -> int:
	var filled: int = current_pack_clears
	if filled >= PACK_CLEARS and not won:
		return 0
	return clampi(filled, 0, PACK_CLEARS)


func pack_just_completed() -> bool:
	return current_pack_clears >= PACK_CLEARS


func should_show_streak_chip() -> bool:
	return streak_days >= 1 and not last_play_date.is_empty()


func streak_chip_text() -> String:
	if not should_show_streak_chip():
		return ""
	return "streak %d" % streak_days


func is_yesterday(prev: String, today: String) -> bool:
	var p: Vector3i = _parse_ymd(prev)
	var t: Vector3i = _parse_ymd(today)
	if p.x <= 0 or t.x <= 0:
		return false
	var prev_unix: int = int(Time.get_unix_time_from_datetime_dict({
		"year": p.x,
		"month": p.y,
		"day": p.z,
		"hour": 12,
		"minute": 0,
		"second": 0,
	}))
	var today_unix: int = int(Time.get_unix_time_from_datetime_dict({
		"year": t.x,
		"month": t.y,
		"day": t.z,
		"hour": 12,
		"minute": 0,
		"second": 0,
	}))
	return today_unix - prev_unix == 86400


func _effective_path() -> String:
	var forced: String = OS.get_environment("TINT_DROP_SAVE_PATH")
	if not forced.is_empty():
		save_path = forced
		return forced
	return save_path


func _last_index() -> int:
	return mini(CAMPAIGN_MAX, level_count - 1)


func _clamp_fields() -> void:
	var last_i: int = _last_index()
	campaign_level_index = clampi(campaign_level_index, 0, last_i)
	current_pack_clears = clampi(current_pack_clears, 0, PACK_CLEARS)
	streak_days = maxi(streak_days, 0)


func _parse_ymd(s: String) -> Vector3i:
	var parts: PackedStringArray = s.split("-")
	if parts.size() != 3:
		return Vector3i.ZERO
	var y: int = int(parts[0])
	var m: int = int(parts[1])
	var d: int = int(parts[2])
	if y < 1 or m < 1 or m > 12 or d < 1 or d > 31:
		return Vector3i.ZERO
	return Vector3i(y, m, d)
