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
var _pack_hero_tex: Texture2D
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
	_pack_hero_tex = _bake_pack_hero()
	set_process(false)
	get_viewport().size_changed.connect(_fit_hero)


func is_showing() -> bool:
	return _showing


func present(pack_complete: bool, campaign_done: bool, filled_pips: int = 0) -> void:
	dismiss()
	_showing = true
	visible = true
	var show_pack: bool = pack_complete or campaign_done
	_hero.texture = _pack_hero_tex if show_pack else TEX_HERO
	_hero.material = null
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

	# Gel PACK COMPLETE only — chroma-key letters after a letter-shaped inpaint
	# of baked CLEARED glyphs in this same still. No second plate, no y_cut.
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


# PACK COMPLETE hero: same cafe still as CLEARED with only the baked gel
# glyphs removed. Mask is letter-shaped (large cyan/pink/orange CCs inside
# the word bbox + hole-fill + 3px dilate). Fill is a local average of nearby
# already-known pixels — never a y_cut band, luma sky wipe, or copy from y=0.
const _BAKE_Y0 := 82
const _BAKE_Y1 := 428
const _BAKE_MIN_CC := 8000
const _BAKE_CLOSE := 5
const _BAKE_DILATE := 3
const _BAKE_SMOOTH := 10


func _bake_pack_hero() -> Texture2D:
	var img: Image = TEX_HERO.get_image()
	if img == null:
		push_warning("WinOverlay: CLEARED still has no CPU image; pack uses raw hero.")
		return TEX_HERO
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 8 or h < 8:
		return TEX_HERO
	var t0: int = Time.get_ticks_msec()
	var src: PackedByteArray = img.get_data()
	var n: int = w * h
	var seed := PackedByteArray()
	seed.resize(n)
	var y0: int = mini(_BAKE_Y0, h - 2)
	var y1: int = mini(_BAKE_Y1, h - 1)
	for y in range(y0, y1 + 1):
		var row: int = y * w
		for x in range(w):
			var i: int = (row + x) * 4
			var c := Vector3(float(src[i]) / 255.0, float(src[i + 1]) / 255.0, float(src[i + 2]) / 255.0)
			if _gel_cyan(c) or _gel_pink(c) or _gel_orange(c):
				seed[row + x] = 1
	var cores: PackedByteArray = _keep_large_ccs(seed, w, h, y0, y1, _BAKE_MIN_CC)
	_fill_holes(cores, w, h, y0, y1)
	_morph(cores, w, h, y0, y1, _BAKE_CLOSE, true)
	_morph(cores, w, h, y0, y1, _BAKE_CLOSE, false)
	_morph(cores, w, h, y0, y1, _BAKE_DILATE, true)
	for y in range(h):
		var row: int = y * w
		if y < y0 or y > y1:
			for x in range(w):
				cores[row + x] = 0
	_inpaint_known(src, cores, w, h, y0, y1)
	img.set_data(w, h, false, Image.FORMAT_RGBA8, src)
	var tex := ImageTexture.create_from_image(img)
	print("WinOverlay: pack hero bake ", Time.get_ticks_msec() - t0, " ms")
	return tex


func _gel_cyan(c: Vector3) -> bool:
	var sat: float = maxf(c.x, maxf(c.y, c.z)) - minf(c.x, minf(c.y, c.z))
	return c.z > c.x + 0.14 and c.z > 0.33 and sat > 0.28


func _gel_pink(c: Vector3) -> bool:
	var sat: float = maxf(c.x, maxf(c.y, c.z)) - minf(c.x, minf(c.y, c.z))
	var luma: float = 0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
	return (
		c.x > 0.45
		and c.z > 0.22
		and c.x > c.y + 0.08
		and c.z > c.y - 0.05
		and sat > 0.18
		and luma > 0.18
		and luma < 0.92
		and (c.x - c.z) < 0.75
	)


func _gel_orange(c: Vector3) -> bool:
	var sat: float = maxf(c.x, maxf(c.y, c.z)) - minf(c.x, minf(c.y, c.z))
	var luma: float = 0.2126 * c.x + 0.7152 * c.y + 0.0722 * c.z
	return (
		c.x > 0.65
		and c.z < 0.28
		and (c.x - c.z) > 0.55
		and sat > 0.55
		and luma > 0.30
		and luma < 0.85
	)


func _keep_large_ccs(seed: PackedByteArray, w: int, h: int, y0: int, y1: int, min_size: int) -> PackedByteArray:
	var n: int = w * h
	var seen := PackedByteArray()
	seen.resize(n)
	var out := PackedByteArray()
	out.resize(n)
	var stack := PackedInt32Array()
	var comp := PackedInt32Array()
	for y in range(y0, y1 + 1):
		for x in range(w):
			var start: int = y * w + x
			if seed[start] == 0 or seen[start] != 0:
				continue
			stack.clear()
			comp.clear()
			stack.push_back(start)
			seen[start] = 1
			while stack.size() > 0:
				var p: int = stack[stack.size() - 1]
				stack.resize(stack.size() - 1)
				comp.push_back(p)
				var px: int = p % w
				var py: int = int(p / w)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = px + dx
						var ny: int = py + dy
						if nx < 0 or nx >= w or ny < y0 or ny > y1:
							continue
						var np: int = ny * w + nx
						if seed[np] == 0 or seen[np] != 0:
							continue
						seen[np] = 1
						stack.push_back(np)
			if comp.size() >= min_size:
				for p2 in comp:
					out[p2] = 1
	return out


func _fill_holes(mask: PackedByteArray, w: int, h: int, y0: int, y1: int) -> void:
	# Flood non-mask from the bbox frame; leftover non-mask inside letters are holes.
	var n: int = w * h
	var reached := PackedByteArray()
	reached.resize(n)
	var stack := PackedInt32Array()
	for x in range(w):
		_try_push_outside(mask, reached, stack, w, y0, y1, x, y0)
		_try_push_outside(mask, reached, stack, w, y0, y1, x, y1)
	for y in range(y0, y1 + 1):
		_try_push_outside(mask, reached, stack, w, y0, y1, 0, y)
		_try_push_outside(mask, reached, stack, w, y0, y1, w - 1, y)
	while stack.size() > 0:
		var p: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var px: int = p % w
		var py: int = int(p / w)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = px + dx
				var ny: int = py + dy
				if nx < 0 or nx >= w or ny < y0 or ny > y1:
					continue
				var np: int = ny * w + nx
				if mask[np] != 0 or reached[np] != 0:
					continue
				reached[np] = 1
				stack.push_back(np)
	for y in range(y0, y1 + 1):
		var row: int = y * w
		for x in range(w):
			var p: int = row + x
			if mask[p] == 0 and reached[p] == 0:
				mask[p] = 1


func _try_push_outside(mask: PackedByteArray, reached: PackedByteArray, stack: PackedInt32Array, w: int, y0: int, y1: int, x: int, y: int) -> void:
	if y < y0 or y > y1 or x < 0 or x >= w:
		return
	var p: int = y * w + x
	if mask[p] != 0 or reached[p] != 0:
		return
	reached[p] = 1
	stack.push_back(p)


func _morph(mask: PackedByteArray, w: int, h: int, y0: int, y1: int, iterations: int, dilate: bool) -> void:
	var n: int = w * h
	for _i in iterations:
		var nxt := PackedByteArray()
		nxt.resize(n)
		for y in range(y0, y1 + 1):
			for x in range(w):
				var p: int = y * w + x
				var any_on: bool = false
				var any_off: bool = false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx: int = x + dx
						var ny: int = y + dy
						var v: int = 0
						if nx >= 0 and nx < w and ny >= y0 and ny <= y1:
							v = mask[ny * w + nx]
						if v != 0:
							any_on = true
						else:
							any_off = true
				if dilate:
					nxt[p] = 1 if any_on else 0
				else:
					nxt[p] = 0 if any_off else 1
		for y in range(y0, y1 + 1):
			var row: int = y * w
			for x in range(w):
				mask[row + x] = nxt[row + x]


func _inpaint_known(src: PackedByteArray, mask: PackedByteArray, w: int, h: int, y0: int, y1: int) -> void:
	# Onion-peel from the letter outline using nearby already-known pixels, then
	# a few 8-neighbor smooth passes on the mask only. Unmasked bytes stay source.
	var n: int = w * h
	var known := PackedByteArray()
	known.resize(n)
	for i in n:
		known[i] = 0 if mask[i] != 0 else 1
	var queue := PackedInt32Array()
	var queued := PackedByteArray()
	queued.resize(n)
	for y in range(y0, y1 + 1):
		for x in range(w):
			var p: int = y * w + x
			if known[p] != 0:
				continue
			if _has_known_neigh(known, w, y0, y1, x, y):
				queued[p] = 1
				queue.push_back(p)
	var qh: int = 0
	while qh < queue.size():
		var p: int = queue[qh]
		qh += 1
		var x: int = p % w
		var y: int = int(p / w)
		if known[p] != 0:
			continue
		var sr: int = 0
		var sg: int = 0
		var sb: int = 0
		var cnt: int = 0
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < 0 or nx >= w or ny < 0 or ny >= h:
					continue
				var np: int = ny * w + nx
				if known[np] == 0:
					continue
				var i: int = np * 4
				sr += src[i]
				sg += src[i + 1]
				sb += src[i + 2]
				cnt += 1
		var i0: int = p * 4
		if cnt > 0:
			src[i0] = int(float(sr) / float(cnt) + 0.5)
			src[i0 + 1] = int(float(sg) / float(cnt) + 0.5)
			src[i0 + 2] = int(float(sb) / float(cnt) + 0.5)
		known[p] = 1
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < 0 or nx >= w or ny < y0 or ny > y1:
					continue
				var np: int = ny * w + nx
				if known[np] == 0 and queued[np] == 0:
					queued[np] = 1
					queue.push_back(np)
	# Smooth mask interiors so the peel does not keep a glyph-shaped seam.
	var tmp := PackedByteArray(src)
	for _pass in _BAKE_SMOOTH:
		for y in range(y0, y1 + 1):
			for x in range(w):
				var p: int = y * w + x
				if mask[p] == 0:
					continue
				var sr: int = 0
				var sg: int = 0
				var sb: int = 0
				var cnt: int = 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx < 0 or nx >= w or ny < 0 or ny >= h:
							continue
						var i: int = (ny * w + nx) * 4
						sr += src[i]
						sg += src[i + 1]
						sb += src[i + 2]
						cnt += 1
				var i0: int = p * 4
				if cnt > 0:
					tmp[i0] = int(float(sr) / float(cnt) + 0.5)
					tmp[i0 + 1] = int(float(sg) / float(cnt) + 0.5)
					tmp[i0 + 2] = int(float(sb) / float(cnt) + 0.5)
		for y in range(y0, y1 + 1):
			for x in range(w):
				var p: int = y * w + x
				if mask[p] == 0:
					continue
				var i0: int = p * 4
				src[i0] = tmp[i0]
				src[i0 + 1] = tmp[i0 + 1]
				src[i0 + 2] = tmp[i0 + 2]



func _has_known_neigh(known: PackedByteArray, w: int, y0: int, y1: int, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or nx >= w or ny < y0 or ny > y1:
				continue
			if known[ny * w + nx] != 0:
				return true
	return false
