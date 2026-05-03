extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay
@onready var presence_area: Area3D = $PresenceArea
@onready var target = null
@onready var enemy_fade: ColorRect = $CanvasLayer/EnemyFade
@onready var bgm_player: AudioStreamPlayer = get_tree().current_scene.get_node("MusicPlayer")
@onready var chase_player: AudioStreamPlayer = get_tree().current_scene.get_node("MusicPlayerChase")

@export var patrol_points_1: Array[Node3D] = []
@export var patrol_points_2: Array[Node3D] = []
@export var patrol_points_3: Array[Node3D] = []
@export var patrol_points_4: Array[Node3D] = []
@export var patrol_points_5: Array[Node3D] = []

@export var speed_walk := 1.7
@export var speed_run := 3.0
@export var walk_anim_speed := 1.0
@export var run_anim_speed := 1.8

@export var attack_range := 2.0
@export var investigate_wait_time := 4.0
@export var patrol_wait_time := 3.0
@export var update_interval := 0.2
@export var attack_duration := 1.5
@export var patrol_reach_distance := 0.35
@export var investigate_reach_distance := 3.0
@export var fade_time := 1.2

const VIEW_ANGLE := 190.0
const SMOOTHING_FACTOR := 0.2

enum State { IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, RETURN }
var state := State.IDLE

var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position := Vector3.ZERO
var return_position := Vector3.ZERO
var update_timer := 0.0
var is_attacking := false
var current_patrol_group: Array[Node3D] = []
var current_patrol_group_number := 1
var gravity = 9.81
var can_trigger_chase_music := false
var player_is_hidden := false
var last_known_player_position := Vector3.ZERO

func _flat_distance(a: Vector3, b: Vector3) -> float:
	a.y = 0; b.y = 0
	return a.distance_to(b)

func _find_player():
	return get_tree().current_scene.get_node("Player/Player")

func _load_patrol_routes():
	var r = get_tree().current_scene.get_node("PatrolRoutes")
	if not r: return
	for i in 1:
		pass
	for i in range(1, 6):
		var n = r.get_node_or_null("Route" + str(i))
		if not n: continue
		var pts: Array[Node3D] = []
		for c in n.get_children():
			if c is Node3D: pts.append(c)
		match i:
			1: patrol_points_1 = pts
			2: patrol_points_2 = pts
			3: patrol_points_3 = pts
			4: patrol_points_4 = pts
			5: patrol_points_5 = pts

func _ready():
	target = _find_player()
	_load_patrol_routes()
	current_patrol_group = patrol_points_1
	_enter_state(State.PATROL if not current_patrol_group.is_empty() else State.IDLE)
	_play_from_start(bgm_player)
	await get_tree().create_timer(5.0).timeout
	can_trigger_chase_music = true

func _physics_process(delta):
	_update_path(delta)
	if state == State.CHASE and player_is_hidden:
		investigate_position = global_position
		_enter_state(State.INVESTIGATE)

	if target and not player_is_hidden and _can_see_player() and state not in [State.CHASE, State.ATTACK]:
		_enter_state(State.CHASE)

	match state:
		State.PATROL: _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE: _state_chase()
		State.ATTACK: _state_attack()
		State.RETURN: _state_return()

	_looking()
	_apply_gravity(delta)
	move_and_slide()

func _state_patrol(delta):
	if current_patrol_group.is_empty(): return
	var p = current_patrol_group[patrol_index].global_position
	if _flat_distance(global_position, p) <= patrol_reach_distance:
		global_position.x = p.x; global_position.z = p.z
		patrol_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, 0.2)
		velocity.z = lerp(velocity.z, 0.0, 0.2)
		if patrol_timer <= 0:
			patrol_index = (patrol_index + 1) % current_patrol_group.size()
			patrol_timer = patrol_wait_time
			agent.set_target_position(current_patrol_group[patrol_index].global_position)
	else:
		_move(speed_walk)

func _state_investigate(delta):
	var d = _flat_distance(global_position, investigate_position)
	if d > investigate_reach_distance:
		_move(speed_walk)
		investigate_timer = investigate_wait_time
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.25)
		velocity.z = lerp(velocity.z, 0.0, 0.25)
		investigate_timer -= delta
		if investigate_timer <= 0:
			_enter_state(State.RETURN)

func _state_chase():
	if not target:
		_enter_state(State.RETURN); return
	if player_is_hidden:
		investigate_position = last_known_player_position
		_enter_state(State.INVESTIGATE); return

	last_known_player_position = target.global_position
	_move(speed_run)

	if _flat_distance(global_position, target.global_position) < attack_range:
		_enter_state(State.ATTACK)
	elif not _can_see_player():
		investigate_position = target.global_position
		_enter_state(State.INVESTIGATE)

func _state_attack():
	if is_attacking: return
	is_attacking = true
	velocity = Vector3.ZERO
	if target and target.has_method("freeze_input"):
		target.freeze_input()
	await get_tree().create_timer(0.2).timeout
	if enemy_fade:
		enemy_fade.fade_in(1.5)
		await enemy_fade.wait_finished()
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _state_return():
	if current_patrol_group.is_empty(): return
	var p = current_patrol_group[patrol_index].global_position
	if _flat_distance(global_position, p) > patrol_reach_distance:
		_move(speed_walk)
	else:
		velocity.x = lerp(velocity.x, 0.0, 0.25)
		velocity.z = lerp(velocity.z, 0.0, 0.25)
		if abs(velocity.x) < 0.05 and abs(velocity.z) < 0.05:
			_enter_state(State.PATROL)

func _move(speed):
	if agent.is_navigation_finished():
		if current_patrol_group.size() > 0:
			agent.set_target_position(current_patrol_group[patrol_index].global_position)
	var p = agent.get_next_path_position()
	var dir = p - global_position
	dir.y = 0
	if dir == Vector3.ZERO: return
	dir = dir.normalized()
	var f = -global_transform.basis.z
	var sm = f.slerp(dir, 0.15).normalized()
	look_at(global_position + sm, Vector3.UP)
	anim.play("Move")
	anim.speed_scale = run_anim_speed if speed == speed_run else walk_anim_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _enter_state(s):
	if state == s: return
	state = s
	match state:
		State.PATROL:
			patrol_timer = patrol_wait_time
			agent.set_target_position(current_patrol_group[patrol_index].global_position)
			await get_tree().create_timer(1.5).timeout
			_return_to_normal_music()
		State.INVESTIGATE:
			investigate_timer = investigate_wait_time
			agent.set_target_position(investigate_position)
			_start_investigate_music()
		State.CHASE:
			_start_chase_music()
		State.ATTACK:
			is_attacking = false
		State.RETURN:
			if current_patrol_group.size() > 0:
				agent.set_target_position(current_patrol_group[patrol_index].global_position)

func _update_path(delta):
	update_timer -= delta
	if update_timer <= 0:
		update_timer = update_interval
		_update_agent_target()

func _update_agent_target():
	if current_patrol_group.is_empty(): return
	match state:
		State.PATROL:
			agent.set_target_position(current_patrol_group[patrol_index].global_position)
		State.CHASE:
			if target and not player_is_hidden:
				agent.set_target_position(target.global_position)
		State.RETURN:
			agent.set_target_position(current_patrol_group[patrol_index].global_position)

func _can_see_player():
	if not target or player_is_hidden: return false
	return (vision_ray.is_colliding() and vision_ray.get_collider() == target) or presence_area.get_overlapping_bodies().has(target)

func set_player_hidden(v):
	player_is_hidden = v
	if v and target:
		last_known_player_position = target.global_position

func _looking():
	if not target: return
	var to = (target.global_position - global_position).normalized()
	var f = -global_transform.basis.z
	if rad_to_deg(acos(clamp(f.dot(to), -1, 1))) > VIEW_ANGLE * 0.5:
		return
	var nd = vision_ray.global_transform.basis.z.slerp(to, SMOOTHING_FACTOR).normalized()
	vision_ray.look_at(vision_ray.global_position + nd, Vector3.UP)

func _apply_gravity(delta):
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta

func _play_from_start(p):
	p.stop(); p.play(0.0)

func _fade_audio(p, t, time):
	var s = p.volume_db
	var i = 0.0
	while i < time:
		i += get_process_delta_time()
		p.volume_db = lerp(s, t, i / time)
		await get_tree().process_frame

func _start_chase_music():
	if not can_trigger_chase_music: return
	_play_from_start(chase_player)
	chase_player.volume_db = -80
	_fade_audio(chase_player, 0.0, fade_time)
	_fade_audio(bgm_player, -80.0, fade_time)

func _start_investigate_music():
	if can_trigger_chase_music and chase_player.playing:
		_fade_audio(chase_player, -10.0, fade_time)

func _return_to_normal_music():
	if not can_trigger_chase_music: return
	if chase_player.playing:
		await _fade_audio(chase_player, -80.0, fade_time)
		chase_player.stop()
	_play_from_start(bgm_player)
	bgm_player.volume_db = -80
	_fade_audio(bgm_player, 0.0, fade_time)

func _set_patrol_group(g, n):
	current_patrol_group = g
	current_patrol_group_number = n
	patrol_index = 0
	if g.size() > 0:
		agent.set_target_position(g[0].global_position)
