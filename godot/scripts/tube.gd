extends Control
class_name TubeView

signal tapped(index: int)

const CAPACITY := 4
const PALETTE: Array[Color] = [
	Color(0.93, 0.33, 0.39),
	Color(0.31, 0.67, 0.95),
	Color(0.33, 0.82, 0.60),
	Color(0.98, 0.78, 0.28),
	Color(0.70, 0.40, 0.90),
]
const TEX_EMPTY := preload("res://assets/ui/tube-empty.png")
## Inner glass well as fractions of tube-empty.png (443x868, 16px pad).
## Split from ad-tubes.png LEFT vial content box (291, 89, 411x836).
const WELL_L := 0.160
const WELL_R := 0.837
const WELL_T := 0.204
const WELL_B := 0.939
const MOUTH_Y := 0.11

var index: int = 0
var chips: Array[int] = []
var selected: bool = false
var shake_x: float = 0.0
var _select_tween: Tween
var _fx_tween: Tween
var _liquid_nudge: float = 0.0
var _art: TextureRect

func _ready() -> void:
	if custom_minimum_size.x < 8.0:
		custom_minimum_size = Vector2(144, 282)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	gui_input.connect(_on_gui_input)
	pivot_offset = custom_minimum_size * 0.5
	_art = TextureRect.new()
	_art.texture = TEX_EMPTY
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.show_behind_parent = true
	_art.anchor_left = 0.0
	_art.anchor_top = 0.0
	_art.anchor_right = 1.0
	_art.anchor_bottom = 1.0
	_art.offset_left = 0.0
	_art.offset_top = 0.0
	_art.offset_right = 0.0
	_art.offset_bottom = 0.0
	add_child(_art)
	_sync_art()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		_sync_art()

func set_chips(next: Array) -> void:
	chips.clear()
	for c in next:
		chips.append(int(c))
	queue_redraw()

func set_selected(on: bool) -> void:
	var was: bool = selected
	selected = on
	_sync_art()
	queue_redraw()
	if on and not was:
		_pop_select()
	elif (not on) and was:
		_settle_select()

func _lift() -> float:
	return -14.0 if selected else 0.0

func _sync_art() -> void:
	if _art == null:
		return
	var lift: float = _lift()
	_art.offset_left = shake_x
	_art.offset_right = shake_x
	_art.offset_top = lift
	_art.offset_bottom = lift

func set_tube_size(w: float, h: float) -> void:
	custom_minimum_size = Vector2(w, h)
	size = Vector2(w, h)
	pivot_offset = Vector2(w, h) * 0.5

func _fitted_tex_rect() -> Rect2:
	var ts := Vector2(443.0, 868.0)
	if _art != null and _art.texture != null:
		ts = Vector2(float(_art.texture.get_width()), float(_art.texture.get_height()))
	var cs: Vector2 = size
	if ts.x < 1.0 or ts.y < 1.0 or cs.x < 1.0 or cs.y < 1.0:
		return Rect2()
	var sc: float = minf(cs.x / ts.x, cs.y / ts.y)
	var fitted: Vector2 = ts * sc
	var origin := Vector2(
		(cs.x - fitted.x) * 0.5 + shake_x,
		(cs.y - fitted.y) * 0.5 + _lift()
	)
	return Rect2(origin, fitted)

func mouth_global_pos() -> Vector2:
	var tr: Rect2 = _fitted_tex_rect()
	if tr.size.x < 1.0:
		return global_position + Vector2(size.x * 0.5 + shake_x, 22.0 + _lift())
	return global_position + Vector2(tr.position.x + tr.size.x * 0.5, tr.position.y + tr.size.y * MOUTH_Y)

func _kill_select_tween() -> void:
	if _select_tween != null and is_instance_valid(_select_tween):
		_select_tween.kill()
	_select_tween = null

func _kill_fx_tween() -> void:
	if _fx_tween != null and is_instance_valid(_fx_tween):
		_fx_tween.kill()
	_fx_tween = null

func _pop_select() -> void:
	_kill_select_tween()
	pivot_offset = size * 0.5
	position.y = 0.0
	scale = Vector2(0.96, 0.96)
	_select_tween = create_tween()
	_select_tween.set_parallel(true)
	_select_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_select_tween.tween_property(self, "position:y", -10.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _settle_select() -> void:
	_kill_select_tween()
	_select_tween = create_tween()
	_select_tween.set_parallel(true)
	_select_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	_select_tween.tween_property(self, "position:y", 0.0, 0.12)

func play_pour_source(dir_sign: float = 1.0) -> void:
	_kill_select_tween()
	_kill_fx_tween()
	pivot_offset = Vector2(size.x * 0.5, size.y - 10.0)
	scale = Vector2.ONE
	rotation = 0.0
	var ang: float = deg_to_rad(12.0) * signf(dir_sign)
	_fx_tween = create_tween()
	_fx_tween.tween_property(self, "rotation", ang, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_interval(0.06)
	_fx_tween.tween_property(self, "rotation", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_callback(func() -> void:
		pivot_offset = size * 0.5
	)

func play_pour_dest() -> void:
	_kill_fx_tween()
	pivot_offset = Vector2(size.x * 0.5, size.y)
	scale = Vector2.ONE
	_liquid_nudge = 0.0
	_fx_tween = create_tween()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_property(self, "scale", Vector2(1.08, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_method(_set_liquid_nudge, 0.0, 1.0, 0.08)
	_fx_tween.chain()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_property(self, "scale", Vector2(0.97, 1.05), 0.10)
	_fx_tween.tween_method(_set_liquid_nudge, 1.0, 0.0, 0.14)
	_fx_tween.chain()
	_fx_tween.set_parallel(false)
	_fx_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_callback(func() -> void:
		pivot_offset = size * 0.5
		_liquid_nudge = 0.0
		queue_redraw()
	)

func _set_liquid_nudge(v: float) -> void:
	_liquid_nudge = v
	queue_redraw()

func play_win_bounce(delay: float) -> void:
	_kill_select_tween()
	_kill_fx_tween()
	pivot_offset = size * 0.5
	scale = Vector2.ONE
	rotation = 0.0
	_fx_tween = create_tween()
	_fx_tween.tween_interval(delay)
	_fx_tween.tween_property(self, "scale", Vector2(1.14, 1.14), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.10)
	_fx_tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func top_color() -> Color:
	if chips.is_empty():
		return Color(0.95, 0.92, 0.78, 0.95)
	return PALETTE[clampi(chips[chips.size() - 1], 0, PALETTE.size() - 1)]

func flash_invalid() -> void:
	var tw: Tween = create_tween()
	tw.tween_method(_set_shake, 0.0, 1.0, 0.18)
	tw.tween_callback(func() -> void:
		shake_x = 0.0
		_sync_art()
		queue_redraw()
	)

func _set_shake(t: float) -> void:
	shake_x = sin(t * PI * 8.0) * 6.0 * (1.0 - t)
	_sync_art()
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(index)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			tapped.emit(index)

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx < 0.6 or ry < 0.6:
		return
	var n: int = 22
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a: float = TAU * float(i) / float(n)
		pts[i] = center + Vector2(cos(a) * rx, sin(a) * ry)
	draw_colored_polygon(pts, col)

func _draw_gel_disc(cx: float, y_top: float, y_bot: float, rx: float, col: Color, round_bottom: bool) -> void:
	var h: float = y_bot - y_top
	if h < 1.0 or rx < 1.0:
		return
	var ry: float = clampf(rx * 0.32, 4.0, h * 0.45)
	var shade := Color(col.r * 0.62, col.g * 0.62, col.b * 0.62, col.a)
	var lid := col.lightened(0.18)
	var hi := col.lightened(0.32)
	if round_bottom:
		var cr: float = minf(rx, h)
		draw_circle(Vector2(cx, y_bot - cr), cr, col, true, -1.0, true)
		var waist: float = y_bot - cr
		if y_top < waist - 0.5:
			var body := PackedVector2Array([
				Vector2(cx - rx, y_top + ry),
				Vector2(cx + rx, y_top + ry),
				Vector2(cx + rx, waist),
				Vector2(cx - rx, waist),
			])
			draw_colored_polygon(body, col)
	else:
		var body := PackedVector2Array([
			Vector2(cx - rx, y_top + ry),
			Vector2(cx + rx, y_top + ry),
			Vector2(cx + rx, y_bot - ry * 0.2),
			Vector2(cx - rx, y_bot - ry * 0.2),
		])
		draw_colored_polygon(body, col)
		_draw_ellipse(Vector2(cx, y_bot - ry * 0.15), rx, ry, col)
	_draw_ellipse(Vector2(cx + rx * 0.28, (y_top + y_bot) * 0.52), rx * 0.38, h * 0.36, Color(shade.r, shade.g, shade.b, 0.40))
	_draw_ellipse(Vector2(cx, y_top + ry * 0.12), rx, ry, lid)
	_draw_ellipse(Vector2(cx - rx * 0.06, y_top + ry * 0.04), rx * 0.72, ry * 0.52, hi)
	draw_circle(Vector2(cx - rx * 0.40, y_top + h * 0.30), maxf(rx * 0.15, 3.0), Color(1, 1, 1, 0.40), true, -1.0, true)
	_draw_ellipse(Vector2(cx - rx * 0.30, y_top + ry * 0.02), rx * 0.20, ry * 0.26, Color(1, 1, 1, 0.28))

func _draw() -> void:
	_sync_art()
	var tr: Rect2 = _fitted_tex_rect()
	if tr.size.x < 4.0 or tr.size.y < 4.0:
		return
	var well := Rect2(
		tr.position.x + tr.size.x * WELL_L,
		tr.position.y + tr.size.y * WELL_T,
		tr.size.x * (WELL_R - WELL_L),
		tr.size.y * (WELL_B - WELL_T)
	)
	var fill_n: int = chips.size()
	if fill_n <= 0:
		return
	var slot_h: float = well.size.y / float(CAPACITY)
	var well_bot: float = well.position.y + well.size.y
	var well_top: float = well.position.y
	var irad: float = well.size.x * 0.5
	var cx: float = well.position.x + irad
	var rx: float = irad - 1.5
	var nudge: float = _liquid_nudge * slot_h * 0.22

	for i in fill_n:
		var col: Color = PALETTE[clampi(chips[i], 0, PALETTE.size() - 1)]
		if selected and _is_top_run(i):
			col = col.lightened(0.12)
		var y0: float = well_bot - float(i) * slot_h
		var y1: float = well_bot - float(i + 1) * slot_h
		if i == fill_n - 1:
			y1 -= nudge
		y1 = maxf(y1, well_top)
		y0 = minf(y0, well_bot)
		if y0 <= y1 + 0.5:
			continue
		_draw_gel_disc(cx, y1, y0, rx, col, i == 0)

func _is_top_run(i: int) -> bool:
	if chips.is_empty():
		return false
	var top_id: int = chips[chips.size() - 1]
	for k in range(chips.size() - 1, -1, -1):
		if chips[k] != top_id:
			return false
		if k == i:
			return true
	return false
