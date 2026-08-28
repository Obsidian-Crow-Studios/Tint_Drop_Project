extends CanvasLayer
class_name StudioSplash

## Cold-boot studio intro. Locked sequence (Jeremias 2026-08-28):
## S1 FeatherPlate 0–3s fade in, 3–6s fade out → S2 WokePlate at 6.0 →
## slash overlay slam at 6.50 (1.8→1.0 in 0.12s) + sfx_jail_door.wav →
## hold ~1.2s, fade 0.4s into TAP TO PLAY.
## Tap skips the current plate only. Leaving S2 early skips slam + wav.
## Once per Main instance (cold boot), not Retry / Next / pack / resume.

signal finished

const FADE_S := 3.0
const STAMP_AT_S := 0.50
const STAMP_SLAM_S := 0.12
const HOLD_S := 1.20
const OUT_S := 0.40
const STAMP_FROM := Vector2(1.8, 1.8)
const VIEW := Vector2(720.0, 1280.0)

const TEX_FEATHER := preload("res://assets/ui/splash/splash-obsidian-crow-720x1280.png")
const TEX_WOKE_WORD := preload("res://assets/ui/splash/splash-woke-word-720x1280.png")
const TEX_STAMP := preload("res://assets/ui/splash/splash-stamp-overlay-720x1280.png")
const SFX_JAIL_DOOR := preload("res://assets/sfx/sfx_jail_door.wav")

var _root: Control
var _screen1: Control
var _screen2: Control
var _stamp: TextureRect
var _sfx: AudioStreamPlayer
var _seq: Tween
var _consumed: bool = false
var _resolved: bool = false
var _playing: bool = false
var _plate: int = 1
var _stamp_started: bool = false


func _ready() -> void:
	layer = 80
	visible = true
	_build()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_fit_stamp)


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
	if is_inside_tree():
		await get_tree().process_frame
	_fit_stamp()
	_run_screen1()
	await finished


func abort() -> void:
	_consumed = true
	_kill_seq()
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

	_screen1 = Control.new()
	_screen1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_screen1)
	_root.add_child(_screen1)
	_screen1.add_child(_make_still(TEX_FEATHER))

	_screen2 = Control.new()
	_screen2.visible = false
	_screen2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(_screen2)
	_root.add_child(_screen2)
	_screen2.add_child(_make_still(TEX_WOKE_WORD))

	_stamp = _make_still(TEX_STAMP)
	_stamp.visible = false
	_stamp.scale = STAMP_FROM
	_screen2.add_child(_stamp)

	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "Master"
	var stream: AudioStream = SFX_JAIL_DOOR
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	_sfx.stream = stream
	add_child(_sfx)


func _make_still(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fill(tr)
	return tr


func _fit_stamp() -> void:
	if _stamp == null:
		return
	_fill(_stamp)
	var sz: Vector2 = _stamp.size
	if sz.x < 8.0 or sz.y < 8.0:
		sz = VIEW
	_stamp.pivot_offset = sz * 0.5


func _reset_visuals() -> void:
	_plate = 1
	_stamp_started = false
	if _root != null:
		_root.modulate = Color(1, 1, 1, 1)
	if _screen1 != null:
		_screen1.visible = true
		_screen1.modulate = Color(1, 1, 1, 0)
	if _screen2 != null:
		_screen2.visible = false
	if _stamp != null:
		_stamp.visible = false
		_stamp.modulate = Color(1, 1, 1, 1)
		_stamp.scale = STAMP_FROM
	_fit_stamp()


func _run_screen1() -> void:
	_plate = 1
	_kill_seq()
	_seq = create_tween()
	_seq.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_seq.tween_property(_screen1, "modulate:a", 1.0, FADE_S).set_trans(Tween.TRANS_LINEAR)
	_seq.tween_property(_screen1, "modulate:a", 0.0, FADE_S).set_trans(Tween.TRANS_LINEAR)
	_seq.tween_callback(_start_screen2)


func _start_screen2() -> void:
	if _resolved:
		return
	_plate = 2
	_stamp_started = false
	if _screen1 != null:
		_screen1.visible = false
	if _screen2 != null:
		_screen2.visible = true
	if _stamp != null:
		_stamp.visible = false
		_stamp.scale = STAMP_FROM
	_fit_stamp()
	_kill_seq()
	_seq = create_tween()
	_seq.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_seq.tween_interval(STAMP_AT_S)
	_seq.tween_callback(_begin_stamp_slam)
	_seq.tween_property(_stamp, "scale", Vector2.ONE, STAMP_SLAM_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_seq.tween_interval(HOLD_S)
	_seq.tween_property(_root, "modulate:a", 0.0, OUT_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_seq.tween_callback(_finish.bind(true))


func _begin_stamp_slam() -> void:
	if _resolved or _plate != 2:
		return
	_stamp_started = true
	_fit_stamp()
	if _stamp != null:
		_stamp.visible = true
		_stamp.scale = STAMP_FROM
	_play_stamp_sfx()


func _play_stamp_sfx() -> void:
	if _sfx == null or _sfx.stream == null:
		return
	_sfx.stop()
	_sfx.play()


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
	_skip_current_plate()
	return true


func _skip_current_plate() -> void:
	if _resolved:
		return
	if _plate == 1:
		_kill_seq()
		_start_screen2()
		return
	# Leaving S2 early: no slam / wav if they have not fired.
	_kill_seq()
	if not _stamp_started and _sfx != null:
		_sfx.stop()
	if not _stamp_started and _stamp != null:
		_stamp.visible = false
	_finish(true)


func _kill_seq() -> void:
	if _seq != null and is_instance_valid(_seq):
		_seq.kill()
	_seq = null


func _finish(emit_done: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_playing = false
	_kill_seq()
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
