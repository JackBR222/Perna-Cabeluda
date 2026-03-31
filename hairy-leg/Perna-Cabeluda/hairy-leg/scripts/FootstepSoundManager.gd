extends AudioStreamPlayer3D

# Referência ao player
@export var player: CharacterBody3D

# Raycast apontando pra baixo
@onready var raycast: RayCast3D = $RayCast3D

# Intervalos de passo
@export var walk_step_interval: float = 0.6
@export var run_step_interval: float = 0.35

# Velocidade mínima pra considerar movimento
@export var min_velocity: float = 0.1

# Sons por tipo de chão
@export var footstep_sounds: Dictionary = {
	"concrete": preload("res://audio/sounds/footstep_concrete.mp3"),
	"grass": preload("res://audio/sounds/footstep_grass.mp3"),
	"default": preload("res://audio/sounds/footstep_concrete.mp3") # fallback = concrete
}

var step_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var is_moving = player.velocity.length() > min_velocity
	var is_on_floor = player.is_on_floor()

	if is_on_floor and is_moving:
		var is_running = Input.is_action_pressed("run")
		var step_interval = run_step_interval if is_running else walk_step_interval

		step_timer -= delta

		if step_timer <= 0.0:
			play_step()
			step_timer = step_interval
	else:
		step_timer = 0.0


func play_step() -> void:
	var floor_type = get_floor_type()

	var sound: AudioStream
	if footstep_sounds.has(floor_type):
		sound = footstep_sounds[floor_type]
	else:
		sound = footstep_sounds["default"]

	stream = sound
	pitch_scale = randf_range(0.9, 1.1)
	play()


func get_floor_type() -> String:
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		# 🔹 PRIORIDADE 1: metadata
		if collider.has_meta("floor_type"):
			return str(collider.get_meta("floor_type"))

		# 🔹 PRIORIDADE 2: grupos
		if collider.is_in_group("grass"):
			return "grass"
		elif collider.is_in_group("concrete"):
			return "concrete"

	return "default"
