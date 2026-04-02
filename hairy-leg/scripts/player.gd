extends CharacterBody3D
class_name Player

var is_hidden: bool = false

# CONFIGURAÇÕES MOVIMENTO
@export var turn_speed: float = 120.0
@export var walk_speed: float = 2.0
@export var run_speed: float = 4.5
const GRAVITY: float = -9.81

# MOVIMENTO
func handle_turn(delta: float) -> void:
	var turn_input = Input.get_axis("turn_left", "turn_right")
	rotation_degrees.y -= turn_input * turn_speed * delta

func handle_walk(_delta: float) -> void:
	var forward_input = Input.get_axis("move_backward", "move_forward")
	var walk_vel = -basis.z * forward_input * walk_speed
	velocity.x = walk_vel.x
	velocity.z = walk_vel.z

func handle_run(_delta: float) -> void:
	var forward_input = Input.get_axis("move_backward", "move_forward")
	var run_vel = -basis.z * forward_input * run_speed
	velocity.x = run_vel.x
	velocity.z = run_vel.z

func handle_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -2.0
	else:
		velocity.y += GRAVITY * delta

# SONS DE PASSO
var step_timer: float = 0.0
@export var walk_step_interval: float = 0.6
@export var run_step_interval: float = 0.35

func play_footstep_sound(delta: float) -> void:
	var moving_forward = Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")
	if is_on_floor() and moving_forward:
		var interval = run_step_interval if Input.is_action_pressed("run") else walk_step_interval
		step_timer -= delta
		if step_timer <= 0.0:
			$FootstepPlayer.play()
			step_timer = interval
	else:
		step_timer = 0.0

# FÍSICAS
func _physics_process(delta: float) -> void:
	handle_turn(delta)
	if Input.is_action_pressed("run"):
		handle_run(delta)
	else:
		handle_walk(delta)
	handle_gravity(delta)
	play_footstep_sound(delta)
	move_and_slide()

# VIDA E MORTE
var hp := 3
func take_damage(amount: int) -> void:
	hp -= amount
	print("Player HP:", hp)
	if hp <= 0:
		die()

func die() -> void:
	print("Player morreu!")
	queue_free()

# ITENS / INTERAÇÃO
@onready var interaction_ray: RayCast3D = $Interact3D
@onready var hold_position: Node3D = $HoldPosition
var held_item: Item = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_handle_interaction()

# Função unificada de interação
func _handle_interaction() -> void:
	if not interaction_ray.is_colliding():
		return
	
	var collider = interaction_ray.get_collider()

	# Se o objeto colidido tiver a função 'interact', chama passando o Player
	if collider.has_method("interact"):
		collider.interact(self)
