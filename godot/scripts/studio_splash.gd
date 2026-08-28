extends CanvasLayer
class_name StudioSplash

## Cold-boot studio intro. Locked sequence (Jeremias 2026-08-28):
## white Obsidian Crow plate (fade 3s in / 3s out) → WOKE + red circle-slash
## stamp + jail-cell SFX → existing TAP TO PLAY. Tap skips the remainder.
## Once per Main instance (cold boot), not after a pack.

signal finished

const FADE_S := 3.0
const STUDIO_PNG := "res://assets/ui/splash/splash-studio.png"
const SFX_STAMP_CELL := "res://assets/sfx/sfx_stamp_cell.wav"
const SFX_JAIL_DOOR := "res://assets/sfx/sfx_jail_door.wav"
const STAMP_RED := Color(0.86, 0.07, 0.10, 1.0)
const BLOOD := Color(0.72, 0.05, 0.08, 1.0)
const QUILL := Color(0.10, 0.10, 0.12, 1.0)

var _root: Control
var _screen1: Control
var _screen2: Control
var _studio_art: TextureRect
var _studio_ph: Control
var _woke: Label
var _stamp: Control
var _sfx: AudioStreamPlayer
var _seq: Tween
var _consumed: bool = false
var _resolved: bool = false
var _playing: bool = false


func _ready() -> void:
	layer = 80
	visible = true
	_build()


func play() -> void:
	if _resolved:
		return
	if _consumed:
		await finished
		return
	_consumed = true
	_playing = true
	visible = true
	if _root != null:
		_root.mouse_filter = Control.MOUSE_FILTER_STOP
		_root.modulate = Color(1, 1, 1, 1)
	_reset_visuals()
	_run_sequence()
	await finished


func abort() -> void:
	_consumed = true
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
		_seq = null
	_finish(false)


func _build() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_fill(_root)
	_root.gui_input.connect(_on_gui_input)
	add_child(_root)

	var under := ColorRect.new()
	under.color = Color(0, 0, 0, 1)
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(under)
	_root.add_child(under)

	_build_screen1()
	_build_screen2()

	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	var stream: AudioStream = _load_stamp_stream()
	if stream != null:
		_sfx.stream = stream
	add_child(_sfx)


func _build_screen1() -> void:
	_screen1 = Control.new()
	_screen1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_screen1)
	_root.add_child(_screen1)

	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 1)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(white)
	_screen1.add_child(white)

	_studio_art = TextureRect.new()
	_studio_art.visible = false
	_studio_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_studio_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_studio_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_studio_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fill(_studio_art)
	_screen1.add_child(_studio_art)

	_studio_ph = CenterContainer.new()
	_studio_ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_studio_ph)
	_screen1.add_child(_studio_ph)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 28)
	_studio_ph.add_child(col)

	col.add_child(_make_quill_placeholder())

	var name_lab := Label.new()
	name_lab.text = "Obsidian Crow Studios"
	name_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lab.add_theme_font_size_override("font_size", 32)
	name_lab.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	col.add_child(name_lab)

	_apply_studio_png()


func _make_quill_placeholder() -> Control:
	# ColorRect stand-in for the crow-feather + 3 blood drops. Replaced when
	# Art drops splash-studio.png.
	var box := Control.new()
	box.custom_minimum_size = Vector2(240, 200)
	box.size = Vector2(240, 200)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vane := ColorRect.new()
	vane.color = QUILL
	vane.position = Vector2(78, 18)
	vane.size = Vector2(52, 96)
	vane.rotation_degrees = 22.0
	vane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(vane)

	var shaft := ColorRect.new()
	shaft.color = Color(0.07, 0.07, 0.08, 1)
	shaft.position = Vector2(112, 28)
	shaft.size = Vector2(10, 152)
	shaft.rotation_degrees = 22.0
	shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(shaft)

	var drops: Array[Vector2] = [
		Vector2(128, 84),
		Vector2(142, 118),
		Vector2(156, 150),
	]
	var sizes: Array[float] = [18.0, 15.0, 12.0]
	for i in drops.size():
		var drop := ColorRect.new()
		drop.color = BLOOD
		var d: float = sizes[i]
		drop.size = Vector2(d, d)
		drop.position = drops[i]
		drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(drop)
	return box


func _apply_studio_png() -> void:
	var tex: Texture2D = _load_studio_png()
	if tex == null:
		if _studio_art != null:
			_studio_art.visible = false
			_studio_art.texture = null
		if _studio_ph != null:
			_studio_ph.visible = true
		return
	_studio_art.texture = tex
	_studio_art.visible = true
	if _studio_ph != null:
		_studio_ph.visible = false


func _build_screen2() -> void:
	_screen2 = Control.new()
	_screen2.visible = false
	_screen2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_screen2)
	_root.add_child(_screen2)

	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(black)
	_screen2.add_child(black)

	_woke = Label.new()
	_woke.text = "WOKE"
	_woke.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_woke.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_woke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_woke.add_theme_font_override("font", _highway_font())
	_woke.add_theme_font_size_override("font_size", 188)
	_woke.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_woke.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_woke.add_theme_constant_override("outline_size", 10)
	_woke.anchor_left = 0.5
	_woke.anchor_top = 0.5
	_woke.anchor_right = 0.5
	_woke.anchor_bottom = 0.5
	_woke.offset_left = -340.0
	_woke.offset_top = -110.0
	_woke.offset_right = 340.0
	_woke.offset_bottom = 110.0
	_woke.pivot_offset = Vector2(340.0, 110.0)
	_screen2.add_child(_woke)

	_stamp = _make_stamp()
	_stamp.anchor_left = 0.5
	_stamp.anchor_top = 0.5
	_stamp.anchor_right = 0.5
	_stamp.anchor_bottom = 0.5
	_stamp.offset_left = -230.0
	_stamp.offset_top = -230.0
	_stamp.offset_right = 230.0
	_stamp.offset_bottom = 230.0
	_stamp.pivot_offset = Vector2(230.0, 230.0)
	_stamp.rotation_degrees = -18.0
	_screen2.add_child(_stamp)


func _make_stamp() -> Control:
	# Drawn ColorRect ring + bar. Not Imagine art. Swap for a TextureRect later.
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.custom_minimum_size = Vector2(460, 460)

	var ring_panel := Panel.new()
	ring_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_panel.anchor_left = 0.0
	ring_panel.anchor_top = 0.0
	ring_panel.anchor_right = 1.0
	ring_panel.anchor_bottom = 1.0
	ring_panel.offset_left = 12.0
	ring_panel.offset_top = 12.0
	ring_panel.offset_right = -12.0
	ring_panel.offset_bottom = -12.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = STAMP_RED
	sb.set_border_width_all(34)
	sb.set_corner_radius_all(999)
	ring_panel.add_theme_stylebox_override("panel", sb)
	host.add_child(ring_panel)

	var bar := ColorRect.new()
	bar.color = STAMP_RED
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.5
	bar.anchor_top = 0.5
	bar.anchor_right = 0.5
	bar.anchor_bottom = 0.5
	bar.offset_left = -168.0
	bar.offset_top = -18.0
	bar.offset_right = 168.0
	bar.offset_bottom = 18.0
	bar.pivot_offset = Vector2(168.0, 18.0)
	bar.rotation_degrees = -38.0
	host.add_child(bar)
	return host


func _highway_font() -> Font:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"Impact",
		"Arial Black",
		"Noto Sans Display",
		"Inter",
		"Nimbus Sans Narrow",
		"Liberation Sans",
		"DejaVu Sans",
		"FreeSans",
	])
	sys.font_weight = 800
	sys.font_stretch = TextServer.FONT_STRETCH_CONDENSED
	return sys


func _reset_visuals() -> void:
	if _screen1 != null:
		_screen1.visible = true
		_screen1.modulate = Color(1, 1, 1, 0)
	if _screen2 != null:
		_screen2.visible = false
	if _woke != null:
		_woke.modulate = Color(1, 1, 1, 0)
		_woke.scale = Vector2(1.08, 1.08)
	if _stamp != null:
		_stamp.modulate = Color(1, 1, 1, 0)
		_stamp.scale = Vector2(2.55, 2.55)
	_apply_studio_png()


func _run_sequence() -> void:
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
	_seq = create_tween()
	_seq.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_seq.tween_property(_screen1, "modulate:a", 1.0, FADE_S).set_trans(Tween.TRANS_LINEAR)
	_seq.tween_property(_screen1, "modulate:a", 0.0, FADE_S).set_trans(Tween.TRANS_LINEAR)
	_seq.tween_callback(_begin_screen2)
	_seq.tween_property(_woke, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_seq.parallel().tween_property(_woke, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_seq.tween_interval(0.18)
	_seq.tween_callback(_begin_stamp_slam)
	_seq.tween_property(_stamp, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_seq.tween_callback(_on_stamp_impact)
	_seq.tween_interval(1.35)
	_seq.tween_property(_root, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_seq.tween_callback(_finish.bind(true))


func _begin_screen2() -> void:
	if _resolved:
		return
	if _screen1 != null:
		_screen1.visible = false
	if _screen2 != null:
		_screen2.visible = true
	if _woke != null:
		_woke.pivot_offset = Vector2(340.0, 110.0)
		_woke.modulate = Color(1, 1, 1, 0)


func _begin_stamp_slam() -> void:
	if _resolved or _stamp == null:
		return
	_stamp.modulate = Color(1, 1, 1, 1)
	_stamp.scale = Vector2(2.55, 2.55)


func _on_stamp_impact() -> void:
	if _resolved:
		return
	_play_stamp_sfx()
	if _stamp == null:
		return
	var punch := create_tween()
	punch.tween_property(_stamp, "scale", Vector2(0.94, 0.94), 0.06)
	punch.tween_property(_stamp, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_stamp_sfx() -> void:
	if _sfx == null or _sfx.stream == null:
		return
	_sfx.stop()
	_sfx.play()


func _load_stamp_stream() -> AudioStream:
	# Canonical hook is sfx_stamp_cell.wav. Main already landed a jail-cell
	# sample under sfx_jail_door.wav — use it until the hook name exists.
	for path in [SFX_STAMP_CELL, SFX_JAIL_DOOR]:
		if not _res_exists(path):
			continue
		var loaded: Resource = load(path)
		if loaded is AudioStream:
			var stream := loaded as AudioStream
			if stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
			return stream
	return null


func _load_studio_png() -> Texture2D:
	if not _res_exists(STUDIO_PNG):
		return null
	var loaded: Resource = load(STUDIO_PNG)
	if loaded is Texture2D:
		return loaded as Texture2D
	return null


func _res_exists(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	return FileAccess.file_exists(path)


func _on_gui_input(event: InputEvent) -> void:
	if _try_skip(event):
		_root.accept_event()


func _input(event: InputEvent) -> void:
	if _try_skip(event):
		get_viewport().set_input_as_handled()


func _try_skip(event: InputEvent) -> bool:
	if not _playing or _resolved:
		return false
	var press := false
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		press = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		press = (event as InputEventScreenTouch).pressed
	if not press:
		return false
	_skip()
	return true


func _skip() -> void:
	if _resolved:
		return
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
		_seq = null
	_finish(true)


func _finish(emit_done: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_playing = false
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
		_seq = null
	if _sfx != null:
		_sfx.stop()
	visible = false
	if _root != null:
		_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if emit_done:
		finished.emit()


func _fill(node: Control) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 1.0
	node.anchor_bottom = 1.0
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
