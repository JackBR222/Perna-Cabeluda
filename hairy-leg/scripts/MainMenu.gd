extends CanvasLayer

@export var default_fade_time: float = 1.0
@export var initial_delay: float = 1.5

# UI
@export var menu_background: TextureRect
@export var fade_overlay: ColorRect
@export var scroll_container: ScrollContainer
@export var vbox_container: VBoxContainer
@export var options_panel: Control
@export var options_back_button: BaseButton
@export var any_press_start: TextureRect

# BACKGROUNDS
@export var bg_press_start: Texture2D
@export var bg_main_menu: Texture2D
@export var bg_options_menu: Texture2D

var tween: Tween
var started: bool = false
var in_options: bool = false

var original_textures := {}
var hover_tweens := {}


# INICIALIZAÇÃO
func _ready() -> void:
	fade_overlay.modulate.a = 1.0

	scroll_container.visible = false
	scroll_container.focus_mode = Control.FOCUS_NONE # evita interferência no foco
	options_panel.visible = false
	any_press_start.visible = true

	menu_background.texture = bg_press_start

	register_buttons()
	await initial_sequence()


# REGISTRAR BOTÕES
func register_buttons() -> void:
	for child in vbox_container.get_children():
		if child is TextureButton:
			var btn := child as TextureButton

			original_textures[btn] = {
				"normal": btn.texture_normal,
				"hover": btn.texture_hover,
				"pressed": btn.texture_pressed
			}

			btn.focus_entered.connect(_on_button_focus_entered.bind(btn))
			btn.focus_exited.connect(_on_button_focus_exited.bind(btn))
			btn.button_down.connect(_on_button_down.bind(btn))
			btn.button_up.connect(_on_button_up.bind(btn))

			# CONTROLE DE MOUSE (mantido)
			btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
			btn.mouse_exited.connect(_on_button_mouse_exited.bind(btn))


# FEEDBACK VISUAL DOS BOTÕES + HOVER PULSE
func _on_button_focus_entered(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["hover"]
	start_hover_pulse(btn)


func _on_button_focus_exited(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["normal"]
	stop_hover_pulse(btn)


func _on_button_down(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["pressed"]


func _on_button_up(btn: TextureButton) -> void:
	if btn.has_focus():
		btn.texture_normal = original_textures[btn]["hover"]
	else:
		btn.texture_normal = original_textures[btn]["normal"]


# CONTROLE DE MOUSE → FOCO ÚNICO GARANTIDO
func _on_button_mouse_entered(btn: TextureButton) -> void:
	btn.grab_focus()


func _on_button_mouse_exited(btn: TextureButton) -> void:
	if not btn.has_focus():
		btn.texture_normal = original_textures[btn]["normal"]
		stop_hover_pulse(btn)


# PULSE DE HOVER
func start_hover_pulse(btn: TextureButton) -> void:
	stop_hover_pulse(btn)

	var t := create_tween().set_loops()
	hover_tweens[btn] = t

	t.tween_property(btn, "modulate", Color(1.8, 1.8, 1.8, 1), 0.6)
	t.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.6)


func stop_hover_pulse(btn: TextureButton) -> void:
	if hover_tweens.has(btn):
		hover_tweens[btn].kill()
		hover_tweens.erase(btn)
		btn.modulate = Color(1, 1, 1, 1)


# FADE IN INICIAL
func initial_sequence() -> void:
	await get_tree().create_timer(initial_delay).timeout
	await fade_out()


# CONTROLE DE INPUT
func _input(event: InputEvent) -> void:
	if in_options:
		if event.is_action_pressed("ui_cancel"):
			close_options()
		return

	if not started:
		if event.is_pressed():
			started = true
			await open_main_menu()
		return


# MENU PRINCIPAL
func open_main_menu() -> void:
	await fade_in()

	menu_background.texture = bg_main_menu
	any_press_start.visible = false
	scroll_container.visible = true

	await fade_out()

	# 🔥 SISTEMA IGUAL GAMEOVER (SEM BUG DE ORDEM)
	focus_first_button()


# FOCO INICIAL (MESMA LÓGICA DO GAMEOVER)
func focus_first_button() -> void:
	for child in vbox_container.get_children():
		if child is BaseButton and child.visible and not child.disabled:
			child.grab_focus()
			return


# AÇÕES DOS BOTÕES
func _on_start_button_pressed() -> void:
	await fade_in()
	get_tree().change_scene_to_file("res://scenes/Game.scn")


func _on_continue_button_pressed() -> void:
	await fade_in()
	Checkpoint.carregar_checkpoint()


func _on_options_button_pressed() -> void:
	open_options()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


# MENU DE OPÇÕES
func open_options() -> void:
	in_options = true
	scroll_container.visible = false
	options_panel.visible = true

	menu_background.texture = bg_options_menu

	await get_tree().process_frame
	options_back_button.grab_focus()


func close_options() -> void:
	in_options = false
	options_panel.visible = false
	scroll_container.visible = true

	menu_background.texture = bg_main_menu

	await get_tree().process_frame
	focus_first_button()


func _on_options_back_button_pressed() -> void:
	close_options()


# FADE SYSTEM
func fade_in(time: float = -1.0) -> void:
	if time <= 0:
		time = default_fade_time
	start_fade(1.0, time)
	await wait_fade()


func fade_out(time: float = -1.0) -> void:
	if time <= 0:
		time = default_fade_time
	start_fade(0.0, time)
	await wait_fade()


func start_fade(target: float, time: float) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", target, time)


func wait_fade() -> void:
	if tween:
		await tween.finished
