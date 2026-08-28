extends CanvasLayer
class_name WinOverlay

signal next_pressed
signal fanfare_ended

const CHROMA := preload("res://shaders/chroma_key.gdshader")
const TEX_HERO := preload("res://assets/ui/win/win-fanfare-cleared.png")
const TEX_PACK := preload("res://assets/ui/win/pack-complete-word.png")
const TEX_PIP_EMPTY := preload("res://assets/ui/pip_empty_20.png")
const TEX_PIP_LIT := preload("res://assets/ui/pip_lit_20.png")
const SFX_FANFARE := preload("res://assets/sfx/sfx_clear_fanfare.wav")
const SFX_CROWD_CHEER := preload("res://assets/sfx/sfx_crowd_cheer.wav")
const HINT_FONT := preload("res://assets/ui/fonts/BubblegumSans-Regular.ttf")

const FANFARE_S := 7.0
const VIEW_W := 720.0
const VIEW_H := 1280.0
const PIP_SIZE := 20.0
const PIP_GAP := 12.0
const PIP_COUNT := 5
const PIP_TOP := 432.0
const WORD_TOP := 48.0
const WORD_H := 140.0
const NEXT_H := 188.0
const NEXT_BOTTOM_PAD := 12.0
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
var _cover: ColorRect
var _hero: TextureRect
var _word: TextureRect
var _spray_host: Control
var _spray_bits: Array[ColorRect] = []
var _fanfare: AudioStreamPlayer
var _cheer: AudioStreamPlayer
var _seq: Tween
var _word_tween: Tween
var _spray_moving: bool = false
var _showing: bool = false


func _ready() -> void:
	layer = 20
	visible = false
	_build()
	set_process(false)
	get_viewport().size_changed.connect(_fit_hero)


func is_showing() -> bool:
	return _showing


func present(pack_complete: bool, campaign_done: bool, filled_pips: int = 0) -> void:
	dismiss()
	_showing = true
	visible = true
	var show_pack: bool = pack_complete or campaign_done
	_hero.texture = TEX_HERO
	_word.visible = show_pack
	_word.texture = _atlas(TEX_PACK, Rect2(65, 405, 1427, 214))
	if campaign_done:
		next_btn.text = "Again"
	else:
		next_btn.text = ""
	_set_pips(filled_pips)
	_fit_hero()
	_reset_visuals(show_pack)
	_play_fanfare()
	_spray_moving = false
	set_process(false)
	for bit in _spray_bits:
		bit.visible = false
	if _is_capture():
		_snap_idle(show_pack)
	else:
		_run_sequence(show_pack)


func dismiss() -> void:
	_showing = false
	_spray_moving = false
	set_process(false)
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
		_seq = null
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

	# Fallback only — the extra-crowd still must cover the 720×1280 frame.
	_cover = ColorRect.new()
	_cover.color = Color(0.22, 0.11, 0.07, 1.0)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_fill(_cover)
	_root.add_child(_cover)

	# One extra-crowd CLEARED still. Full texture, no atlas band, no chroma.
	# KEEP_ASPECT_CENTERED on a rect sized to cover the viewport.
	_hero = TextureRect.new()
	_hero.texture = TEX_HERO
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_hero.anchor_left = 0.5
	_hero.anchor_right = 0.5
	_hero.anchor_top = 0.5
	_hero.anchor_bottom = 0.5
	_root.add_child(_hero)
	_fit_hero()

	# Gel PACK COMPLETE only — chroma-key the letters over the same cafe still.
	# Do not composite a second background plate (that was the y=430 hard seam).
	# Baked CLEARED stays; do not inpaint/blur it into a bokeh band.
	_word = _keyed_rect(_atlas(TEX_PACK, Rect2(65, 405, 1427, 214)))
	_word.visible = false
	_word.anchor_left = 0.5
	_word.anchor_right = 0.5
	_word.anchor_top = 0.0
	_word.anchor_bottom = 0.0
	_word.offset_left = -350.0
	_word.offset_right = 350.0
	_word.offset_top = WORD_TOP
	_word.offset_bottom = WORD_TOP + WORD_H
	_word.pivot_offset = Vector2(350.0, WORD_H * 0.5)
	_root.add_child(_word)

	_spray_host = Control.new()
	_spray_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_spray_host)
	_root.add_child(_spray_host)
	_build_spray_bits()

	_build_overlay_pips()

	# Click target over the still's baked wood+icing Next. No second plaque.
	next_btn = Button.new()
	next_btn.text = ""
	next_btn.anchor_left = 0.5
	next_btn.anchor_right = 0.5
	next_btn.anchor_top = 1.0
	next_btn.anchor_bottom = 1.0
	next_btn.offset_left = -300.0
	next_btn.offset_right = 300.0
	next_btn.offset_top = -(NEXT_H + NEXT_BOTTOM_PAD)
	next_btn.offset_bottom = -NEXT_BOTTOM_PAD
	next_btn.custom_minimum_size = Vector2(600.0, NEXT_H)
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


func _fit_hero() -> void:
	if _hero == null or _hero.texture == null:
		return
	var vs := Vector2(VIEW_W, VIEW_H)
	if is_inside_tree():
		var vis := get_viewport().get_visible_rect().size
		if vis.x > 1.0 and vis.y > 1.0:
			vs = vis
	var tex_sz: Vector2 = _hero.texture.get_size()
	if tex_sz.x < 1.0 or tex_sz.y < 1.0:
		return
	var s: float = maxf(vs.x / tex_sz.x, vs.y / tex_sz.y)
	var dw: float = tex_sz.x * s
	var dh: float = tex_sz.y * s
	_hero.offset_left = -dw * 0.5
	_hero.offset_right = dw * 0.5
	_hero.offset_top = -dh * 0.5
	_hero.offset_bottom = dh * 0.5


func _keyed_rect(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var mat := ShaderMaterial.new()
	mat.shader = CHROMA
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
	var total: float = PIP_SIZE * float(PIP_COUNT) + PIP_GAP * float(PIP_COUNT - 1)
	var x0: float = (VIEW_W - total) * 0.5
	var y: float = PIP_TOP
	for i in PIP_COUNT:
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
		var x: float = x0 + float(i) * (PIP_SIZE + PIP_GAP)
		pip.offset_left = x
		pip.offset_top = y
		pip.offset_right = x + PIP_SIZE
		pip.offset_bottom = y + PIP_SIZE
		pip.custom_minimum_size = Vector2(PIP_SIZE, PIP_SIZE)
		pip.pivot_offset = Vector2(PIP_SIZE * 0.5, PIP_SIZE * 0.5)
		_root.add_child(pip)
		_pips.append(pip)


func _set_pips(filled: int) -> void:
	var n: int = clampi(filled, 0, _pips.size())
	for i in _pips.size():
		var pip: TextureRect = _pips[i]
		pip.texture = TEX_PIP_LIT if i < n else TEX_PIP_EMPTY
		pip.scale = Vector2.ONE
		if i < n and not _is_capture():
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


func _reset_visuals(show_pack: bool) -> void:
	_hero.modulate = Color(1, 1, 1, 1)
	_word.visible = show_pack
	_word.modulate = Color(1, 1, 1, 0.0 if show_pack else 1.0)
	_word.scale = Vector2(0.82, 0.82) if show_pack else Vector2.ONE
	next_btn.modulate = Color(1, 1, 1, 0)
	next_btn.disabled = true
	for bit in _spray_bits:
		bit.visible = false
	_seed_spray_bits()


func _snap_idle(show_pack: bool) -> void:
	_hero.modulate = Color(1, 1, 1, 1)
	_word.visible = show_pack
	_word.modulate = Color(1, 1, 1, 1)
	_word.scale = Vector2.ONE
	next_btn.modulate = Color(1, 1, 1, 1)
	next_btn.disabled = false
	_spray_moving = false
	for bit in _spray_bits:
		bit.visible = false


func _seed_spray_bits() -> void:
	var origins: Array[Vector2] = [
		Vector2(210.0, 700.0),
		Vector2(360.0, 680.0),
		Vector2(510.0, 700.0),
	]
	for i in _spray_bits.size():
		var bit: ColorRect = _spray_bits[i]
		var origin: Vector2 = origins[i % origins.size()]
		bit.position = origin + Vector2((randf() - 0.5) * 70.0, randf() * 360.0)
		bit.rotation = randf() * 0.6 - 0.3
		bit.set_meta("spd", 140.0 + randf() * 160.0)
		bit.set_meta("ox", origin.x)
		bit.set_meta("oy", origin.y)


func _run_sequence(show_pack: bool) -> void:
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
	_seq = create_tween()
	_seq.set_parallel(true)
	if show_pack:
		_seq.tween_property(_word, "modulate:a", 1.0, 0.22)
		_seq.tween_property(_word, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_seq.tween_property(_word, "scale", Vector2.ONE, 0.16).set_delay(0.22)
		_seq.tween_callback(_start_word_pulse).set_delay(0.40)
	_seq.tween_property(next_btn, "modulate:a", 1.0, 0.25).set_delay(1.05)
	_seq.tween_callback(func() -> void:
		next_btn.disabled = false
	).set_delay(1.05)
	_seq.tween_callback(_enter_idle).set_delay(FANFARE_S)


func _start_word_pulse() -> void:
	if not _showing or not _word.visible:
		return
	if _word_tween != null and is_instance_valid(_word_tween):
		_word_tween.kill()
	_word.pivot_offset = Vector2(350.0, WORD_H * 0.5)
	_word_tween = create_tween()
	_word_tween.set_loops()
	_word_tween.tween_property(_word, "scale", Vector2(1.045, 1.045), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_word_tween.tween_property(_word, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _enter_idle() -> void:
	if not _showing:
		return
	_spray_moving = true
	set_process(true)
	_play_idle_cheer()
	for bit in _spray_bits:
		bit.visible = true


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
	if _is_capture():
		return
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


func _is_capture() -> bool:
	return OS.get_environment("TINT_DROP_CAPTURE") != ""


func _on_next_pressed() -> void:
	dismiss()
	next_pressed.emit()
