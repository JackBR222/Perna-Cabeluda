extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay
@onready var presence_area: Area3D = $PresenceArea

# ALVO
@export var target: CharacterBody3D

# CONFIGURAÇÃO
@export var patrol_points_1: Array[Node3D] = []
@export var patrol_points_2: Array[Node3D] = []
@export var patrol_points_3: Array[Node3D] = []
@export var patrol_points_4: Array[Node3D] = []
@export var patrol_points_5: Array[Node3D] = []

@export var speed_walk: float = 1.7
@export var speed_run: float = 3.0
@export var attack_range: float = 2.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var update_interval: float = 0.2
@export var attack_duration: float = 1.5

const VIEW_ANGLE: float = 190.0
const SMOOTHING_FACTOR = 0.2

# ESTADOS
enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE

# CONTROLE
var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position: Vector3
var return_position: Vector3
var update_timer := 0.0
var is_attacking := false

var current_patrol_group: Array[Node3D] = []
var current_patrol_group_number: int = 1

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# READY
func _ready() -> void:
	if not target:
		target = get_tree().get_root().find_node("Player", true, false)

	_set_patrol_group(patrol_points_1, 1)
	_enter_state(State.IDLE if current_patrol_group.is_empty() else State.PATROL)

# LOOP PRINCIPAL
func _physics_process(delta: float) -> void:
	_update_path(delta)

	# DETECÇÃO GLOBAL
	if _can_see_player() and state not in [State.CHASE, State.ATTACK]:
		_enter_state(State.CHASE)

	match state:
		State.PATROL:      _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE:       _state_chase()
		State.ATTACK:      _state_attack()
		State.RETURN:      _state_return()

	_looking()
	_apply_gravity(delta)
	move_and_slide()

# ESTADOS
func _state_patrol(delta: float) -> void:
	if agent.is_navigation_finished():
		patrol_timer -= delta
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			_go_to_next_patrol_point()
	else:
		_move(speed_walk)

func _state_investigate(delta: float) -> void:
	if agent.is_navigation_finished():
		investigate_timer -= delta
		if investigate_timer <= 0.0:
			_enter_state(State.RETURN)
	else:
		_move(speed_walk)

func _state_chase() -> void:
	if not target:
		_enter_state(State.RETURN)
		return

	_move(speed_run)

	if global_position.distance_to(target.global_position) < attack_range:
		_enter_state(State.ATTACK)
	elif not _can_see_player():
		investigate_position = target.global_position
		_enter_state(State.INVESTIGATE)

func _state_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	velocity = Vector3.ZERO
	# anim.play("Attack")

	await get_tree().create_timer(attack_duration).timeout
	_enter_state(State.CHASE)

func _state_return() -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	else:
		_move(speed_walk)

# MOVIMENTO
func _move(speed: float) -> void:
	if agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	_walk_to(agent.get_next_path_position(), speed)

func _walk_to(next_pos: Vector3, speed: float) -> void:
	anim.play("Move")
	_move_towards(next_pos, speed)

func _move_towards(next_pos: Vector3, speed: float) -> void:
	var dir = next_pos - global_position
	dir.y = 0.0

	if dir.length() == 0:
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		velocity.z = lerp(velocity.z, 0.0, SMOOTHING_FACTOR)
		return

	dir = dir.normalized()

	var forward = -global_transform.basis.z
	var new_dir = forward.slerp(dir, 0.12).normalized()
	look_at(global_position + new_dir, Vector3.UP)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

# ESTADO / NAV
func _enter_state(new_state: State) -> void:
	state = new_state

	match state:
		State.PATROL:
			patrol_timer = patrol_wait_time
			_go_to_next_patrol_point()

		State.INVESTIGATE:
			investigate_timer = investigate_wait_time
			agent.set_target_position(investigate_position)

		State.CHASE:
			return_position = global_position

		State.ATTACK:
			is_attacking = false

		State.RETURN:
			agent.set_target_position(return_position)

func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if current_patrol_group.size() > 0:
				agent.set_target_position(current_patrol_group[patrol_index].global_position)
		State.CHASE:
			if target:
				agent.set_target_position(target.global_position)

func _update_path(delta: float) -> void:
	update_timer -= delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval

# DETECÇÃO
func _can_see_player() -> bool:
	if not target:
		return false

	return (
		(vision_ray.is_colliding() and vision_ray.get_collider() == target) or
		presence_area.get_overlapping_bodies().has(target)
	)

func _looking() -> void:
	if not target:
		return

	var to_player = (target.global_position - global_position).normalized()
	var forward = -global_transform.basis.z

	var angle = rad_to_deg(acos(clamp(forward.dot(to_player), -1.0, 1.0)))
	if angle > VIEW_ANGLE * 0.5:
		return

	var ray_forward = -vision_ray.global_transform.basis.z
	var new_dir = ray_forward.slerp(to_player, SMOOTHING_FACTOR).normalized()

	vision_ray.look_at(vision_ray.global_transform.origin + new_dir, Vector3.UP)

# GRAVIDADE
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

# SOM
func hear_noise(pos: Vector3) -> void:
	if state not in [State.CHASE, State.ATTACK]:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)

# PATRULHA
func _go_to_next_patrol_point() -> void:
	patrol_index = (patrol_index + 1) % current_patrol_group.size()
	agent.set_target_position(current_patrol_group[patrol_index].global_position)

func set_patrol_group(group_number: int) -> void:
	var new_group: Array[Node3D]

	match group_number:
		1: new_group = patrol_points_1
		2: new_group = patrol_points_2
		3: new_group = patrol_points_3
		4: new_group = patrol_points_4
		5: new_group = patrol_points_5
		_: return

	if new_group == current_patrol_group:
		return

	_set_patrol_group(new_group, group_number)

func _set_patrol_group(group: Array[Node3D], group_number: int) -> void:
	current_patrol_group = group
	current_patrol_group_number = group_number
	patrol_index = 0

	if current_patrol_group.size() > 0:
		agent.set_target_position(current_patrol_group[0].global_position)
