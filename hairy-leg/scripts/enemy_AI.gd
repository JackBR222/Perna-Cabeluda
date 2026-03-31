extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay

# ALVO
@export var target: CharacterBody3D

# CONFIGURAÇÃO
@export var patrol_points: Array[Node3D] = []
@export var speed_walk: float = 1.7
@export var speed_run: float = 3.0
@export var attack_range: float = 2.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var update_interval: float = 0.2
@export var attack_duration: float = 1.5  # tempo do ataque em segundos

const VIEW_ANGLE: float = 190.0
const SMOOTHING_FACTOR = 0.2

# ESTADOS
enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE

var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position: Vector3
var return_position: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var update_timer := 0.0
var is_attacking: bool = false  # controla ataque único por entrada no estado

# READY
func _ready() -> void:
	if not target:
		target = get_tree().get_root().find_node("Player", true, false)
		if target:
			print("Alvo encontrado automaticamente:", target.name)
		else:
			print("Nenhum alvo encontrado! Arraste um nó no Inspector.")
	else:
		print("Alvo definido manualmente:", target.name)

	_enter_state(State.IDLE if patrol_points.is_empty() else State.PATROL)

# LOOP PRINCIPAL
func _physics_process(_delta: float) -> void:
	_update_path(_delta)

	match state:
		State.IDLE:        _state_idle()
		State.PATROL:      _state_patrol(_delta)
		State.INVESTIGATE: _state_investigate(_delta)
		State.CHASE:       _state_chase(_delta)
		State.ATTACK:      _state_attack()
		State.RETURN:      _state_return(_delta)

	_looking()
	_apply_gravity(_delta)
	move_and_slide()

# ESTADOS
func _state_idle() -> void:
	if _can_see_player():
		_enter_state(State.CHASE)

func _state_patrol(_delta: float) -> void:
	if agent.is_navigation_finished():
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			_stop_and_idle()
		else:
			patrol_timer -= _delta
			if patrol_timer <= 0.0:
				_go_to_next_patrol_point()
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

func _state_investigate(_delta: float) -> void:
	if agent.is_navigation_finished():
		if investigate_timer <= 0.0:
			investigate_timer = investigate_wait_time
			_stop_and_idle()
		else:
			investigate_timer -= _delta
			if investigate_timer <= 0.0:
				_enter_state(State.RETURN)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

func _state_chase(_delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return

	_walk_to(agent.get_next_path_position(), speed_run)

	if global_transform.origin.distance_to(target.global_transform.origin) < attack_range:
		_enter_state(State.ATTACK)
	elif not _can_see_player():
		investigate_position = target.global_transform.origin
		_enter_state(State.INVESTIGATE)

func _state_attack() -> void:
	# só dispara ataque uma vez por entrada no estado
	if not is_attacking:
		is_attacking = true
		velocity = Vector3.ZERO
		print("Ataque!")  # apenas uma vez
		# anim.play("Attack")  # futuramente quando tiver animação
		await get_tree().create_timer(attack_duration).timeout
		_enter_state(State.CHASE)

func _state_return(_delta: float) -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	elif _can_see_player():
		_enter_state(State.CHASE)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

# FUNÇÕES AUXILIARES
func _enter_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PATROL:
			patrol_timer = 0
			_go_to_next_patrol_point()
		State.INVESTIGATE:
			investigate_timer = 0.0
			agent.set_target_position(investigate_position)
		State.CHASE, State.INVESTIGATE:
			return_position = global_transform.origin
		State.ATTACK:
			is_attacking = false  # reseta para permitir novo ataque

func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if patrol_points.size() > 0:
				agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
		State.INVESTIGATE:
			agent.set_target_position(investigate_position)
		State.CHASE:
			if target:
				agent.set_target_position(target.global_transform.origin)
		State.RETURN:
			agent.set_target_position(return_position)

func _walk_to(next_pos: Vector3, speed: float) -> void:
	# anim.play("Walk")  # futuramente
	_move_towards(next_pos, speed)

func _stop_and_idle() -> void:
	velocity = Vector3.ZERO
	# anim.play("Idle")  # futuramente

func _go_to_next_patrol_point() -> void:
	patrol_index = (patrol_index + 1) % patrol_points.size()
	agent.set_target_position(patrol_points[patrol_index].global_transform.origin)

func _move_towards(next_pos: Vector3, speed: float) -> void:
	var dir = next_pos - global_transform.origin
	dir.y = 0.0
	if is_zero_approx(dir.length()):
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		velocity.z = lerp(velocity.z, 0.0, SMOOTHING_FACTOR)
		return

	dir = dir.normalized()
	var forward = -global_transform.basis.z
	var new_dir = forward.slerp(dir, 0.12).normalized()
	look_at(global_transform.origin + new_dir, Vector3.UP)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _update_path(_delta: float) -> void:
	update_timer -= _delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval

func _apply_gravity(_delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * _delta
	else:
		velocity.y = 0.0

# VISÃO
func _can_see_player() -> bool:
	return target and vision_ray.is_colliding() and vision_ray.get_collider() == target

func _looking() -> void:
	if not target:
		return

	var to_player = (target.global_transform.origin - global_transform.origin).normalized()
	var forward = -global_transform.basis.z
	var angle_deg = rad_to_deg(acos(clamp(forward.dot(to_player), -1.0, 1.0)))
	if angle_deg > VIEW_ANGLE * 0.5:
		return

	var ray_forward = -vision_ray.global_transform.basis.z
	var new_dir = ray_forward.slerp(to_player, SMOOTHING_FACTOR).normalized()
	vision_ray.look_at(vision_ray.global_transform.origin + new_dir, Vector3.UP)

# SOM
func hear_noise(pos: Vector3) -> void:
	if state not in [State.CHASE, State.ATTACK]:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)
