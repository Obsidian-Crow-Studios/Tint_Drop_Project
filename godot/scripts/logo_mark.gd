extends Control
class_name LogoMark

const LOGO_PATH := "res://assets/ui/logo-tint-drop.png"
const DRIP_LOOP := 1.6
const SHIMMER_S := 2.0

var _art: CanvasItem
var _drip_t: float = 0.0
var _splash_t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(560, 240)
	size = Vector2(560, 240)
	pivot_offset = Vector2(280, 120)
	clip_contents = false
	if ResourceLoader.exists(LOGO_PATH):
		var tr := TextureRect.new()
		tr.texture = load(LOGO_PATH)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.anchor_left = 0.0
		tr.anchor_top = 0.0
		tr.anchor_right = 1.0
		tr.anchor_bottom = 1.0
		tr.offset_left = 0.0
		tr.offset_top = 0.0
		tr.offset_right = 0.0
		tr.offset_bottom = 0.0
		add_child(tr)
		_art = tr
	else:
		var ph := ColorRect.new()
		ph.color = Color(0.07, 0.09, 0.14, 0.62)
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ph.anchor_left = 0.0
		ph.anchor_top = 0.0
		ph.anchor_right = 1.0
		ph.anchor_bottom = 1.0
		ph.offset_left = 0.0
		ph.offset_top = 0.0
		ph.offset_right = 0.0
		ph.offset_bottom = 0.0
		add_child(ph)
		_art = ph
		var lab := Label.new()
		lab.text = "TINT DROP"
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 28)
		lab.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86))
		lab.anchor_left = 0.0
		lab.anchor_top = 0.0
		lab.anchor_right = 1.0
		lab.anchor_bottom = 1.0
		lab.offset_bottom = -18.0
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lab)
	_start_shimmer()
	play_splash()

func _start_shimmer() -> void:
	if _art == null:
		return
	var cols: Array[Color] = [
		Color(1.00, 0.88, 0.96),
		Color(0.78, 0.96, 1.00),
		Color(1.00, 0.94, 0.76),
		Color(0.86, 1.00, 0.90),
		Color(0.90, 0.86, 1.00),
		Color(1.00, 0.88, 0.80),
	]
	var tw: Tween = create_tween()
	tw.set_loops()
	var step: float = SHIMMER_S / float(cols.size())
	for c in cols:
		tw.tween_property(_art, "modulate", c, step)

func play_splash() -> void:
	_splash_t = 0.2
	scale = Vector2(0.92, 0.92)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.10, 1.10), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.10)

func play_pop() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.07)

func _process(delta: float) -> void:
	_drip_t = fmod(_drip_t + delta, DRIP_LOOP)
	if _splash_t > 0.0:
		_splash_t = maxf(_splash_t - delta, 0.0)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 8.0 or h < 8.0:
		return
	var cx: float = w * 0.5
	var well_y: float = h - 11.0
	var well_r: float = 15.0
	draw_circle(Vector2(cx, well_y), well_r, Color(0.10, 0.14, 0.20, 0.50))
	draw_arc(Vector2(cx, well_y), well_r, 0.0, TAU, 28, Color(0.70, 0.88, 1.00, 0.50), 2.0, true)
	draw_circle(Vector2(cx, well_y), well_r - 5.0, Color(0.62, 0.16, 0.55, 0.32))
	var u: float = _drip_t / DRIP_LOOP
	var drop_y: float
	var drop_r: float = 7.0
	var bob: float = sin(Time.get_ticks_msec() * 0.004) * 1.6
	if u < 0.62:
		var t: float = u / 0.62
		t = t * t
		drop_y = 10.0 + t * (well_y - 20.0)
	elif u < 0.78:
		drop_y = well_y - 8.0
		drop_r = 7.0 + (u - 0.62) * 18.0
	else:
		drop_y = well_y - 6.0 + bob
		drop_r = 6.4
	var col := Color(1.0, 0.78, 0.18, 0.94)
	draw_circle(Vector2(cx, drop_y), drop_r, col)
	draw_circle(Vector2(cx - drop_r * 0.28, drop_y - drop_r * 0.32), drop_r * 0.34, Color(1, 1, 1, 0.55))
	if u >= 0.62 and u < 0.84:
		var rip: float = (u - 0.62) / 0.22
		draw_arc(Vector2(cx, well_y), well_r + rip * 12.0, PI, TAU, 18, Color(1.0, 0.85, 0.35, 0.42 * (1.0 - rip)), 2.0, true)
	if _splash_t > 0.0:
		var s: float = 1.0 - _splash_t / 0.2
		for i in 6:
			var ang: float = float(i) / 6.0 * TAU + s * 0.4
			var p: Vector2 = Vector2(cx, well_y) + Vector2(cos(ang), sin(ang)) * (10.0 + s * 24.0)
			draw_circle(p, 3.2 * (1.0 - s), Color(0.45, 0.92, 1.0, 0.72 * (1.0 - s)))
