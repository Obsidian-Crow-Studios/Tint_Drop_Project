extends CanvasLayer
class_name WinOverlay

signal next_pressed
signal fanfare_ended

const CHROMA := preload("res://shaders/chroma_key.gdshader")
const TEX_BURST := preload("res://assets/ui/win/fanfare-burst.png")
const TEX_PEAK := preload("res://assets/ui/win/fanfare-peak.png")
const TEX_IDLE := preload("res://assets/ui/win/fanfare-idle.png")
const TEX_CAST := preload("res://assets/ui/win/cafe-cast.png")
const TEX_TUBES := preload("res://assets/ui/win/burst-tubes.png")
const TEX_CLEARED := preload("res://assets/ui/win/cleared-word.png")
const TEX_PACK := preload("res://assets/ui/win/pack-complete-word.png")
const TEX_NEXT := preload("res://assets/ui/win/next-plaque.png")
const TEX_PIP_EMPTY := preload("res://assets/ui/pip_empty_20.png")
const TEX_PIP_LIT := preload("res://assets/ui/pip_lit_20.png")
const SFX_FANFARE := preload("res://assets/sfx/sfx_clear_fanfare.wav")
const SFX_CROWD_CHEER := preload("res://assets/sfx/sfx_crowd_cheer.wav")
const HINT_FONT := preload("res://assets/ui/fonts/BubblegumSans-Regular.ttf")

const FANFARE_S := 7.0
const BURST_S := 1.5
const UI_CAPTION := Color8(243, 230, 216)
const UI_HERO := Color8(224, 122, 74)
const UI_ESPRESSO := Color8(59, 30, 22, 255)

const SPRAY_COLS: Array[Color] = [
	Color(0.18, 0.86, 0.98, 0.92),
	Color(0.96, 0.22, 0.62, 0.92),
	Color(0.98, 0.58, 0.12, 0.92),
]

var next_btn: Button
var _pips: Array[TextureRect] = []

var _root: Control
var _dim: ColorRect
var _burst: TextureRect
var _peak: TextureRect
var _idle: TextureRect
var _cast: TextureRect
var _tubes: TextureRect
var _tubes_spray: TextureRect
var _word: TextureRect
var _glow: ColorRect
var _spray_host: Control
var _spray_bits: Array[ColorRect] = []
var _fanfare: AudioStreamPlayer
var _cheer: AudioStreamPlayer
var _seq: Tween
var _spray_tween: Tween
var _word_tween: Tween
var _spray_moving: bool = false
var _showing: bool = false
var _tubes_base_top: float = -640.0
var _tubes_base_bot: float = 80.0

func _ready() -> void:
	layer = 20
	visible = false
	_build()
	set_process(false)


func is_showing() -> bool:
	return _showing


func present(pack_complete: bool, campaign_done: bool, filled_pips: int = 0) -> void:
	dismiss()
	_showing = true
	visible = true
	if pack_complete or campaign_done:
		_word.texture = _atlas(TEX_PACK, Rect2(58, 398, 1442, 229))
	else:
		_word.texture = _atlas(TEX_CLEARED, Rect2(38, 332, 1475, 333))
	if campaign_done:
		next_btn.text = "Again"
	elif pack_complete:
		next_btn.text = "Next pack"
	else:
		next_btn.text = ""
	_set_pips(filled_pips)
	_reset_visuals()
	_play_fanfare()
	_spray_moving = true
	set_process(true)
	for bit in _spray_bits:
		bit.visible = true
	_run_sequence()


func dismiss() -> void:
	_showing = false
	_spray_moving = false
	set_process(false)
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
		_seq = null
	if _spray_tween != null and is_instance_valid(_spray_tween):
		_spray_tween.kill()
		_spray_tween = null
	if _word_tween != null and is_instance_valid(_word_tween):
		_word_tween.kill()
		_word_tween = null
	_stop_audio()
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_fill(_root)
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0.05, 0.04, 0.08, 0.36)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_fill(_dim)
	_root.add_child(_dim)

	_glow = ColorRect.new()
	_glow.color = Color(1.0, 0.92, 0.78, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.anchor_left = 0.08
	_glow.anchor_right = 0.92
	_glow.anchor_top = 0.04
	_glow.anchor_bottom = 0.42
	_glow.offset_left = 0.0
	_glow.offset_right = 0.0
	_glow.offset_top = 0.0
	_glow.offset_bottom = 0.0
	_root.add_child(_glow)

	_burst = _fanfare_layer(TEX_BURST, 0.42, 0.02)
	_peak = _fanfare_layer(TEX_PEAK, 0.42, 0.16)
	_idle = _fanfare_layer(TEX_IDLE, 0.42, 0.16)
	_root.add_child(_burst)
	_root.add_child(_peak)
	_root.add_child(_idle)

	_tubes = _keyed_rect(
		_atlas(TEX_TUBES, Rect2(112, 8, 1305, 978)),
		false
	)
	_tubes.anchor_left = 0.5
	_tubes.anchor_right = 0.5
	_tubes.anchor_top = 1.0
	_tubes.anchor_bottom = 1.0
	_tubes.offset_left = -340.0
	_tubes.offset_right = 340.0
	_tubes.offset_top = _tubes_base_top
	_tubes.offset_bottom = _tubes_base_bot
	_root.add_child(_tubes)

	_tubes_spray = _keyed_rect(
		_atlas(TEX_TUBES, Rect2(112, 8, 1305, 978)),
		false
	)
	_tubes_spray.anchor_left = 0.5
	_tubes_spray.anchor_right = 0.5
	_tubes_spray.anchor_top = 1.0
	_tubes_spray.anchor_bottom = 1.0
	_tubes_spray.offset_left = -340.0
	_tubes_spray.offset_right = 340.0
	_tubes_spray.offset_top = _tubes_base_top
	_tubes_spray.offset_bottom = _tubes_base_bot
	_tubes_spray.modulate = Color(1, 1, 1, 0)
	_root.add_child(_tubes_spray)

	_cast = _keyed_rect(
		_atlas(TEX_CAST, Rect2(0, 188, 1536, 692)),
		false
	)
	_cast.anchor_left = 0.5
	_cast.anchor_right = 0.5
	_cast.anchor_top = 1.0
	_cast.anchor_bottom = 1.0
	_cast.offset_left = -460.0
	_cast.offset_right = 460.0
	_cast.offset_top = -430.0
	_cast.offset_bottom = 20.0
	_root.add_child(_cast)

	_word = _keyed_rect(_atlas(TEX_CLEARED, Rect2(38, 332, 1475, 333)), false)
	_word.anchor_left = 0.5
	_word.anchor_right = 0.5
	_word.anchor_top = 0.0
	_word.anchor_bottom = 0.0
	_word.offset_left = -320.0
	_word.offset_right = 320.0
	_word.offset_top = 220.0
	_word.offset_bottom = 420.0
	_word.pivot_offset = Vector2(320.0, 100.0)
	_root.add_child(_word)

	_spray_host = Control.new()
	_spray_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_spray_host)
	_root.add_child(_spray_host)
	_build_spray_bits()

	_build_overlay_pips()

	next_btn = Button.new()
	next_btn.text = "Next"
	next_btn.anchor_left = 0.0
	next_btn.anchor_right = 0.0
	next_btn.anchor_top = 0.0
	next_btn.anchor_bottom = 0.0
	next_btn.offset_left = 120.0
	next_btn.offset_top = 920.0
	next_btn.offset_right = 600.0
	next_btn.offset_bottom = 1120.0
	next_btn.position = Vector2(120.0, 920.0)
	next_btn.size = Vector2(480.0, 200.0)
	next_btn.custom_minimum_size = Vector2(480.0, 200.0)
	next_btn.add_theme_font_override("font", HINT_FONT)
	next_btn.add_theme_font_size_override("font_size", 36)
	next_btn.add_theme_color_override("font_color", UI_CAPTION)
	next_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	next_btn.add_theme_color_override("font_pressed_color", UI_HERO)
	next_btn.add_theme_color_override("font_focus_color", UI_CAPTION)
	next_btn.add_theme_color_override("font_outline_color", UI_ESPRESSO)
	next_btn.add_theme_constant_override("outline_size", 8)
	var empty := StyleBoxEmpty.new()
	next_btn.add_theme_stylebox_override("normal", empty)
	next_btn.add_theme_stylebox_override("hover", empty)
	next_btn.add_theme_stylebox_override("pressed", empty)
	next_btn.add_theme_stylebox_override("focus", empty)
	next_btn.add_theme_stylebox_override("disabled", empty)
	var plaque := _keyed_rect(_atlas(TEX_NEXT, Rect2(62, 268, 1414, 470)), false)
	plaque.show_behind_parent = true
	_fill(plaque)
	next_btn.add_child(plaque)
	next_btn.pressed.connect(_on_next_pressed)
	_root.add_child(next_btn)

	_fanfare = AudioStreamPlayer.new()
	_fanfare.stream = SFX_FANFARE
	_fanfare.bus = "Master"
	add_child(_fanfare)

	_cheer = AudioStreamPlayer.new()
	var cheer_stream: AudioStream = SFX_CROWD_CHEER
	if cheer_stream is AudioStreamWAV:
		var wav := cheer_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_cheer.stream = cheer_stream
	_cheer.bus = "Master"
	add_child(_cheer)


func _fanfare_layer(tex: Texture2D, crop_top: float, crop_bottom: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.anchor_left = 0.5
	tr.anchor_right = 0.5
	tr.anchor_top = 0.5
	tr.anchor_bottom = 0.5
	tr.offset_left = -700.0
	tr.offset_right = 700.0
	tr.offset_top = -470.0
	tr.offset_bottom = 470.0
	var mat := ShaderMaterial.new()
	mat.shader = CHROMA
	mat.set_shader_parameter("green_cut", 0.18)
	mat.set_shader_parameter("black_cut", 0.20)
	mat.set_shader_parameter("black_soft", 0.10)
	mat.set_shader_parameter("sat_cut", 0.28)
	mat.set_shader_parameter("sat_soft", 0.12)
	mat.set_shader_parameter("crop_top", crop_top)
	mat.set_shader_parameter("crop_bottom", crop_bottom)
	mat.set_shader_parameter("spill", 0.4)
	tr.material = mat
	return tr


func _keyed_rect(tex: Texture2D, fanfare: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = CHROMA
	if fanfare:
		mat.set_shader_parameter("green_cut", 0.18)
		mat.set_shader_parameter("black_cut", 0.11)
		mat.set_shader_parameter("sat_cut", 0.16)
	else:
		mat.set_shader_parameter("green_cut", 0.14)
		mat.set_shader_parameter("green_soft", 0.10)
		mat.set_shader_parameter("black_cut", 0.0)
		mat.set_shader_parameter("sat_cut", 0.0)
		mat.set_shader_parameter("crop_top", 0.0)
		mat.set_shader_parameter("crop_bottom", 0.0)
		mat.set_shader_parameter("spill", 0.6)
	tr.material = mat
	return tr


func _atlas(tex: Texture2D, region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = region
	a.filter_clip = true
	return a


func _fill(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _build_overlay_pips() -> void:
	_pips.clear()
	var gap: float = 12.0
	var sz: float = 20.0
	var n: int = 5
	var total: float = sz * float(n) + gap * float(n - 1)
	var x0: float = (720.0 - total) * 0.5
	for i in n:
		var pip := TextureRect.new()
		pip.texture = TEX_PIP_EMPTY
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pip.anchor_left = 0.0
		pip.anchor_right = 0.0
		pip.anchor_top = 0.0
		pip.anchor_bottom = 0.0
		var x: float = x0 + float(i) * (sz + gap)
		pip.offset_left = x
		pip.offset_top = 496.0
		pip.offset_right = x + sz
		pip.offset_bottom = 516.0
		pip.position = Vector2(x, 496.0)
		pip.size = Vector2(sz, sz)
		pip.custom_minimum_size = Vector2(sz, sz)
		pip.pivot_offset = Vector2(10.0, 10.0)
		_root.add_child(pip)
		_pips.append(pip)


func _set_pips(filled: int) -> void:
	var n: int = clampi(filled, 0, _pips.size())
	for i in _pips.size():
		var pip: TextureRect = _pips[i]
		pip.texture = TEX_PIP_LIT if i < n else TEX_PIP_EMPTY
		pip.scale = Vector2.ONE
		if i < n:
			pip.scale = Vector2(1.35, 1.35)
			var tw: Tween = create_tween()
			tw.tween_property(pip, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_spray_bits() -> void:
	_spray_bits.clear()
	for i in 24:
		var bit := ColorRect.new()
		var sz: float = 7.0 + float(i % 5) * 2.2
		bit.size = Vector2(sz, sz * 1.35)
		bit.pivot_offset = bit.size * 0.5
		bit.color = SPRAY_COLS[i % SPRAY_COLS.size()]
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bit.visible = false
		_spray_host.add_child(bit)
		_spray_bits.append(bit)


func _reset_visuals() -> void:
	_burst.modulate = Color(1, 1, 1, 1)
	_peak.modulate = Color(1, 1, 1, 0)
	_idle.modulate = Color(1, 1, 1, 0)
	_cast.modulate = Color(1, 1, 1, 0)
	_tubes.modulate = Color(1, 1, 1, 1)
	_tubes.offset_top = _tubes_base_top + 90.0
	_tubes.offset_bottom = _tubes_base_bot + 90.0
	_tubes_spray.modulate = Color(1, 1, 1, 0)
	_tubes_spray.offset_top = _tubes_base_top
	_tubes_spray.offset_bottom = _tubes_base_bot
	_word.modulate = Color(1, 1, 1, 0)
	_word.scale = Vector2(0.78, 0.78)
	_glow.color.a = 0.0
	next_btn.modulate = Color(1, 1, 1, 0)
	next_btn.disabled = true
	for bit in _spray_bits:
		bit.visible = false
	_seed_spray_bits()


func _seed_spray_bits() -> void:
	var origins: Array[Vector2] = [
		Vector2(220.0, 760.0),
		Vector2(360.0, 740.0),
		Vector2(500.0, 760.0),
	]
	for i in _spray_bits.size():
		var bit: ColorRect = _spray_bits[i]
		var origin: Vector2 = origins[i % origins.size()]
		bit.position = origin + Vector2((randf() - 0.5) * 70.0, randf() * 420.0)
		bit.rotation = randf() * 0.6 - 0.3
		bit.set_meta("spd", 140.0 + randf() * 160.0)
		bit.set_meta("ox", origin.x)
		bit.set_meta("oy", origin.y)


func _run_sequence() -> void:
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
	_seq = create_tween()
	_seq.set_parallel(true)
	_seq.tween_property(_cast, "modulate:a", 1.0, 0.28)
	_seq.tween_property(_word, "modulate:a", 1.0, 0.22)
	_seq.tween_property(_word, "scale", Vector2(1.10, 1.10), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_seq.tween_property(_glow, "color:a", 0.22, 0.35)
	_seq.tween_property(_tubes, "offset_top", _tubes_base_top - 70.0, BURST_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_seq.tween_property(_tubes, "offset_bottom", _tubes_base_bot - 70.0, BURST_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_seq.tween_property(next_btn, "modulate:a", 1.0, 0.25).set_delay(1.05)
	_seq.tween_callback(func() -> void:
		next_btn.disabled = false
	).set_delay(1.05)
	_seq.tween_property(_burst, "modulate:a", 0.0, 0.45).set_delay(BURST_S)
	_seq.tween_property(_peak, "modulate:a", 1.0, 0.45).set_delay(BURST_S)
	_seq.tween_property(_word, "scale", Vector2.ONE, 0.16).set_delay(0.22)
	_seq.tween_callback(_start_word_pulse).set_delay(0.40)
	_seq.tween_property(_peak, "modulate:a", 0.0, 0.40).set_delay(FANFARE_S)
	_seq.tween_property(_idle, "modulate:a", 1.0, 0.40).set_delay(FANFARE_S)
	_seq.tween_callback(_enter_idle).set_delay(FANFARE_S)


func _start_word_pulse() -> void:
	if not _showing:
		return
	if _word_tween != null and is_instance_valid(_word_tween):
		_word_tween.kill()
	_word.pivot_offset = Vector2(320.0, 100.0)
	_word_tween = create_tween()
	_word_tween.set_loops()
	_word_tween.tween_property(_word, "scale", Vector2(1.045, 1.045), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_word_tween.tween_property(_word, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _enter_idle() -> void:
	if not _showing:
		return
	set_process(true)
	_play_idle_cheer()
	for bit in _spray_bits:
		bit.visible = true
	_tubes_spray.modulate = Color(1, 1, 1, 0.72)
	if _spray_tween != null and is_instance_valid(_spray_tween):
		_spray_tween.kill()
	_spray_tween = create_tween()
	_spray_tween.set_loops()
	_spray_tween.tween_property(_tubes_spray, "offset_top", _tubes_base_top - 220.0, 1.15).set_trans(Tween.TRANS_LINEAR)
	_spray_tween.parallel().tween_property(_tubes_spray, "offset_bottom", _tubes_base_bot - 220.0, 1.15).set_trans(Tween.TRANS_LINEAR)
	_spray_tween.parallel().tween_property(_tubes_spray, "modulate:a", 0.0, 1.15)
	_spray_tween.tween_callback(func() -> void:
		_tubes_spray.offset_top = _tubes_base_top + 40.0
		_tubes_spray.offset_bottom = _tubes_base_bot + 40.0
		_tubes_spray.modulate.a = 0.75
	)


func _process(delta: float) -> void:
	if not _spray_moving:
		return
	for bit in _spray_bits:
		if not is_instance_valid(bit):
			continue
		var spd: float = float(bit.get_meta("spd"))
		bit.position.y -= spd * delta
		bit.rotation += delta * 1.4
		if bit.position.y < -24.0:
			var ox: float = float(bit.get_meta("ox"))
			var oy: float = float(bit.get_meta("oy"))
			bit.position = Vector2(ox + (randf() - 0.5) * 80.0, oy + randf() * 40.0)
			bit.set_meta("spd", 140.0 + randf() * 170.0)


func _play_fanfare() -> void:
	if _cheer != null:
		_cheer.stop()
	if _fanfare == null or _fanfare.stream == null:
		return
	_fanfare.stop()
	_fanfare.play()


func _play_idle_cheer() -> void:
	if not _showing:
		return
	if _fanfare != null:
		_fanfare.stop()
	fanfare_ended.emit()
	if _cheer == null or _cheer.stream == null:
		return
	_cheer.stop()
	_cheer.play()


func _stop_audio() -> void:
	if _fanfare != null:
		_fanfare.stop()
	if _cheer != null:
		_cheer.stop()


func _on_next_pressed() -> void:
	dismiss()
	next_pressed.emit()
