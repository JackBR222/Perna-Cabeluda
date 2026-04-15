extends AudioStreamPlayer3D

# PLAYER
@export var player: CharacterBody3D

# RAYCAST
@onready var raycast: RayCast3D = $RayCast3D

# INTERVALOS POR ANIMAÇÃO
@export var walk_forward_step_interval: float = 0.6
@export var walk_backward_step_interval: float = 0.75
@export var run_step_interval: float = 0.35
@export var turn_left_step_interval: float = 0.9
@export var turn_right_step_interval: float = 0.9
@export var turn_180_step_interval: float = 1.0
@export var idle_step_interval: float = 999.0 # nunca toca

var step_timer: float = 0.0
var last_anim: String = ""


# LOOP
func _physics_process(delta: float) -> void:
	if player == null:
		return

	var is_on_floor := player.is_on_floor()

	if not is_on_floor:
		step_timer = 0.0
		return

	var anim_name := get_player_anim()

	if anim_name != last_anim:
		last_anim = anim_name
		step_timer = 0.0

	step_timer -= delta

	if step_timer <= 0.0:
		var interval := get_interval_for_anim(anim_name)

		if interval < 999.0:
			play_step()

		step_timer = interval


func get_player_anim() -> String:
	if player.has_method("get_current_anim"):
		return player.get_current_anim()

	return ""


# DEFINE INTERVALO BASEADO NA ANIMAÇÃO
func get_interval_for_anim(anim_name: String) -> float:
	match anim_name:
		"Figner|Run":
			return run_step_interval
		"Figner|Forward Move":
			return walk_forward_step_interval
		"Figner|Backward Move":
			return walk_backward_step_interval
		"Figner|Turn Left":
			return turn_left_step_interval
		"Figner|Turn Right":
			return turn_right_step_interval
		"Figner|Turn 180":
			return turn_180_step_interval
		_:
			return idle_step_interval


# TOCA SOM
func play_step() -> void:
	var floor_type := get_floor_type()

	var sound: AudioStream
	if floor_type == "grass":
		sound = preload("res://audio/sounds/footstep_grass.mp3")
	else:
		sound = preload("res://audio/sounds/footstep_concrete.mp3")

	stream = sound
	pitch_scale = randf_range(0.9, 1.1)
	play()


# TIPO DE CHÃO
func get_floor_type() -> String:
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider.has_meta("floor_type"):
			return str(collider.get_meta("floor_type"))

		if collider.is_in_group("grass"):
			return "grass"
		elif collider.is_in_group("concrete"):
			return "concrete"

	return "default"
