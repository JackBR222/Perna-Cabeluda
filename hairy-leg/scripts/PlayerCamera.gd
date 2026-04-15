extends Camera3D

@export var player: CharacterBody3D
@export var distance: float = 3.5
@export var height: float = 4.5
@export var rotation_speed: float = 90.0
@export var smooth_speed: float = 5.0
@export var vertical_offset: float = 3.0

var current_angle: float = 0.0
var target_position: Vector3

func _ready():
	if not player:
		push_error("Camera precisa da referência ao player!")
	target_position = global_transform.origin

func _process(delta):
	handle_input(delta)
	update_camera(delta)

# INPUT
func handle_input(delta):
	if Input.is_action_pressed("cam_turn_left"):
		current_angle -= rotation_speed * delta
	if Input.is_action_pressed("cam_turn_right"):
		current_angle += rotation_speed * delta

# MOVIMENTO DA CÂMERA
func update_camera(delta):
	if not player:
		return

	var player_pos = player.global_transform.origin
	var rad = deg_to_rad(current_angle)

	target_position = player_pos + Vector3(
		distance * cos(rad),
		height,
		distance * sin(rad)
	)

	global_transform.origin = global_transform.origin.lerp(target_position, smooth_speed * delta)
	look_at(player_pos + Vector3(0, vertical_offset, 0), Vector3.UP)
