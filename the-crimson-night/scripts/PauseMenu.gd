extends CanvasLayer

@onready var player = get_tree().current_scene.get_node("Player/Player")

@export var background: TextureRect
@export var panel: Control
@export var options_panel: Control

@export var resume_button: TextureButton
@export var options_button: TextureButton
@export var main_menu_button: TextureButton
@export var options_back_button: BaseButton

@export var bg_pause: Texture2D
@export var bg_options: Texture2D

@export var ui_click_sound: AudioStream
@export var ui_hover_sound: AudioStream

@onready var music_preview_player: AudioStreamPlayer = $MusicPreviewPlayer
@onready var sfx_preview_player: AudioStreamPlayer = $SFXPreviewPlayer

@onready var music_slider: HSlider = $OptionsPanel/Center/MusicSlider
@onready var sfx_slider: HSlider = $OptionsPanel/Center/SFXSlider

var paused := false
var input_locked := false

var can_play_music_preview := true
var can_play_sfx_preview := true

@onready var ui_click_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var ui_hover_player: AudioStreamPlayer = AudioStreamPlayer.new()

var focused_button: Control = null
var button_tweens := {}


# INIT
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel.visible = false
	options_panel.visible = false

	add_child(ui_click_player)
	ui_click_player.bus = "SFX"
	ui_click_player.stream = ui_click_sound

	add_child(ui_hover_player)
	ui_hover_player.bus = "SFX"
	ui_hover_player.stream = ui_hover_sound

	_register_button(resume_button)
	_register_button(options_button)
	_register_button(main_menu_button)
	_register_button(options_back_button)

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)


# INPUT
func _input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("pause_game"):
		if not options_panel.visible:
			toggle_pause()

	elif event.is_action_pressed("ui_cancel"):
		if options_panel.visible:
			close_options()
		elif paused:
			toggle_pause()


# BLOQUEIO DE INPUT
func set_ui_blocked(blocked: bool) -> void:
	var mode := Control.MOUSE_FILTER_IGNORE if blocked else Control.MOUSE_FILTER_STOP

	var controls := [
		panel,
		options_panel,
		resume_button,
		options_button,
		main_menu_button,
		options_back_button,
		music_slider,
		sfx_slider,
		background
	]

	for c in controls:
		if c:
			c.mouse_filter = mode

	for b in [resume_button, options_button, main_menu_button, options_back_button]:
		if b:
			b.disabled = blocked


# PAUSE
func toggle_pause() -> void:
	input_locked = true
	set_ui_blocked(true)

	paused = !paused
	get_tree().paused = paused

	panel.visible = paused
	options_panel.visible = false

	if paused:
		background.texture = bg_pause
		resume_button.grab_focus()

	await get_tree().process_frame

	input_locked = false
	set_ui_blocked(false)


# OPTIONS
func open_options() -> void:
	panel.visible = false
	options_panel.visible = true
	background.texture = bg_options

	await get_tree().process_frame
	options_back_button.grab_focus()


func close_options() -> void:
	options_panel.visible = false
	panel.visible = true
	background.texture = bg_pause

	await get_tree().process_frame
	resume_button.grab_focus()


# AUDIO
func _on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)
	_play_preview(music_preview_player, "music")


func _on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)
	_play_preview(sfx_preview_player, "sfx")


func _play_preview(_stream_player: AudioStreamPlayer, type: String) -> void:
	var flag = "can_play_%s_preview" % type

	if not self.get(flag):
		return

	self.set(flag, false)
	_stream_player.play()

	await get_tree().create_timer(0.5).timeout
	self.set(flag, true)


# ACTIONS
func _on_resume_pressed() -> void:
	ui_click_player.play()
	toggle_pause()


func _on_options_pressed() -> void:
	ui_click_player.play()
	open_options()


func _on_options_back_pressed() -> void:
	ui_click_player.play()
	close_options()


func _on_main_menu_pressed() -> void:
	ui_click_player.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# FOCUS SYSTEM
func _register_button(btn: Control) -> void:
	if btn == null:
		return

	btn.focus_entered.connect(_on_button_focus.bind(btn))
	btn.focus_exited.connect(_on_button_unfocus.bind(btn))
	btn.mouse_entered.connect(func():
		if not input_locked:
			btn.grab_focus()
	)


func _on_button_focus(btn: Control) -> void:
	focused_button = btn
	ui_hover_player.play()
	_apply_hover(btn)
	_start_pulse(btn)


func _on_button_unfocus(btn: Control) -> void:
	if focused_button == btn:
		focused_button = null
	_apply_normal(btn)
	_stop_pulse(btn)


# VISUAL STATES
func _apply_normal(btn: Control) -> void:
	btn.modulate = Color.WHITE


func _apply_hover(btn: Control) -> void:
	btn.modulate = Color(1.3, 1.3, 1.3)


# PULSE
func _start_pulse(btn: Control) -> void:
	_stop_pulse(btn)

	var t := create_tween().set_loops()
	button_tweens[btn] = t

	t.tween_property(btn, "modulate", Color(1.6,1.6,1.6), 0.4)
	t.tween_property(btn, "modulate", Color(1.1,1.1,1.1), 0.4)


func _stop_pulse(btn: Control) -> void:
	if button_tweens.has(btn):
		button_tweens[btn].kill()
		button_tweens.erase(btn)
