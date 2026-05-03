extends AnimatedSprite3D
class_name GlowPulse

@export var pulse_visible_time: float = 0.5
@export var pulse_hidden_time: float = 2.0

var pulse_timer: float = 0.0
var pulse_visible: bool = true

var active: bool = true


func _ready() -> void:
	# começa já visível e animando
	pulse_visible = true
	pulse_timer = 0.0
	visible = true

	play()


func _process(delta: float) -> void:
	if not active:
		visible = false
		return

	pulse_timer += delta

	if pulse_visible:
		if pulse_timer >= pulse_visible_time:
			pulse_visible = false
			pulse_timer = 0.0
			visible = false
	else:
		if pulse_timer >= pulse_hidden_time:
			pulse_visible = true
			pulse_timer = 0.0
			visible = true


func set_active(value: bool) -> void:
	active = value

	# reinicia o ciclo quando liga
	if active:
		pulse_timer = 0.0
		pulse_visible = true
		visible = true
		play()
	else:
		visible = false
