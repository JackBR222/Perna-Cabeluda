class_name Player
extends CharacterBody3D

# Configurações de movimento
@export_group("Movement Settings")
@export var turn_speed: float = 160.0
@export var walk_speed: float = 110.0
@export var run_speed: float = 250.0

# Constantes
const GRAVITY: float = -9.81

# Virar / Rotacionar
func handle_turn(delta: float) -> void:
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	rotation_degrees.y -= turn_dir * turn_speed * delta

# Andando
func handle_walk(delta: float) -> void:
	var forward_input = Input.get_axis("move_backward", "move_forward")
	var walk_velocity = -basis.z * forward_input * walk_speed * delta
	velocity.x = walk_velocity.x
	velocity.z = walk_velocity.z

# Correndo
func handle_run(delta: float) -> void:
	var forward_input = Input.get_axis("move_backward", "move_forward")
	var run_velocity = -basis.z * forward_input * run_speed * delta
	velocity.x = run_velocity.x
	velocity.z = run_velocity.z

# Gravidade
func handle_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -2.0
	else:
		velocity.y += GRAVITY * delta

# Som de passo dinâmico
var step_timer: float = 0.0
@export var walk_step_interval: float = 0.6
@export var run_step_interval: float = 0.35

func play_footstep_sound(delta: float) -> void:
	var moving_forward = Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")
	if is_on_floor() and moving_forward:
		# Ajusta intervalo dependendo se está correndo
		var step_interval = run_step_interval if Input.is_action_pressed("run") else walk_step_interval
		step_timer -= delta
		if step_timer <= 0.0:
			var footstep_player = $FootstepPlayer
			footstep_player.play()
			step_timer = step_interval
	else:
		step_timer = 0.0  # reset quando para de andar

# Física
func _physics_process(delta: float) -> void:
	handle_turn(delta)

	if Input.is_action_pressed("run"):
		handle_run(delta)
	else:
		handle_walk(delta)

	handle_gravity(delta)
	play_footstep_sound(delta)

	move_and_slide()

#Vida e Morte
@onready var health_bar = get_tree().get_root().find_child("HealthBar", true, false)

var hp := 3

func take_damage(amount: int):
	hp -= amount
	print("Player HP:", hp)

	if hp <= 0:
		die()

func die():
	print("Player morreu!")
	queue_free()
