extends CharacterBody3D
class_name Player

# ESTADO
var is_hidden: bool = false
var input_enabled: bool = true

# CONFIGURAÇÕES
@export var turn_speed: float = 120.0
@export var walk_speed: float = 2.0
@export var run_speed: float = 4.5
const GRAVITY: float = -9.81

# INPUT CACHE
var input_turn := 0.0
var input_forward := 0.0
var input_running := false

# NODES
@onready var interaction_ray: RayCast3D = $Interact3D
@onready var hold_position: Node3D = $HoldPosition

# ITENS
var held_item: Item = null

# PASSOS
var step_timer: float = 0.0
@export var walk_step_interval: float = 0.6
@export var run_step_interval: float = 0.35

# QUICK TURN
@export var quick_turn_speed: float = 720.0 # graus por segundo
var is_quick_turning: bool = false
var target_rotation_y: float = 0.0

# LOOP PRINCIPAL
func _physics_process(delta: float) -> void:
	if not input_enabled:
		_apply_gravity(delta)
		move_and_slide()
		return
	
	_read_input()
	_apply_rotation(delta)
	_apply_movement()
	_apply_gravity(delta)
	_handle_footsteps(delta)
	
	move_and_slide()

# INPUT
func _read_input() -> void:
	input_turn = Input.get_axis("turn_left", "turn_right")
	input_forward = Input.get_axis("move_backward", "move_forward")
	input_running = Input.is_action_pressed("run")
	
	# Quick turn só inicia se não estiver girando
	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning:
		_start_quick_turn()

func _start_quick_turn() -> void:
	is_quick_turning = true
	target_rotation_y = rotation_degrees.y + 180.0
	target_rotation_y = fmod(target_rotation_y, 360.0)

func _apply_rotation(delta: float) -> void:
	if is_quick_turning:
		var difference = (target_rotation_y - rotation_degrees.y)
		difference = fmod(difference + 180.0, 360.0) - 180.0
		var step = quick_turn_speed * delta
		
		if abs(difference) <= step:
			rotation_degrees.y = target_rotation_y
			is_quick_turning = false
		else:
			rotation_degrees.y += step * sign(difference)
	else:
		rotation_degrees.y -= input_turn * turn_speed * delta

# MOVIMENTO
func _apply_movement() -> void:
	var speed = run_speed if input_running else walk_speed
	var direction = -basis.z * input_forward
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -2.0
	else:
		velocity.y += GRAVITY * delta

# PASSOS
func _handle_footsteps(delta: float) -> void:
	var moving = abs(input_forward) > 0.1
	if is_on_floor() and moving:
		var interval = run_step_interval if input_running else walk_step_interval
		step_timer -= delta
		if step_timer <= 0.0:
			$FootstepPlayer.play()
			step_timer = interval
	else:
		step_timer = 0.0

# INTERAÇÃO
func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	
	if event.is_action_pressed("interact"):
		_handle_interaction()

func _handle_interaction() -> void:
	if not interaction_ray.is_colliding():
		return
	
	var collider = interaction_ray.get_collider()
	if collider.has_method("interact"):
		collider.interact(self)

# MORTE
func die() -> void:
	print("Player morreu!")
	queue_free()
