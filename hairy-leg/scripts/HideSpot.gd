extends StaticBody3D
class_name HideSpot

@export var hide_point: Node3D
@export var exit_position: Node3D
@export var vignette: CanvasItem
@export var player_camera: Camera3D

# CONFIG DO EFEITO
@export var hidden_distance: float = 2
@export var hidden_height: float = 2.5
@export var hidden_rotation_speed: float = 45.0

var hidden_player: Player = null

# Backup dos valores
var original_distance: float
var original_height: float
var original_rotation_speed: float

func _ready() -> void:
	if vignette:
		vignette.visible = false

func interact(player: Node) -> void:
	if not player is Player:
		return

	if hidden_player != null:
		return

	hide_player(player)

# ESCONDER
func hide_player(player: Player) -> void:
	hidden_player = player
	
	print("Player se escondeu")

	# Teleporte
	if hide_point:
		player.global_transform = hide_point.global_transform

	if not player_camera:
		player_camera = player.get_node_or_null("Camera3D")

	if not player_camera:
		push_warning("Camera3D não encontrada!")
		return

	# Salva valores
	original_distance = player_camera.distance
	original_height = player_camera.height
	original_rotation_speed = player_camera.rotation_speed

	# Aplica zoom + ajuste
	player_camera.distance = hidden_distance
	player_camera.height = hidden_height
	player_camera.rotation_speed = hidden_rotation_speed

	# TRAVA PLAYER DE VERDADE
	player.input_enabled = false
	player.velocity = Vector3.ZERO

	# Desativa física completamente
	player.set_physics_process(false)

	# Desativa colisão
	player.set_collision_layer(0)
	player.set_collision_mask(0)

	player.visible = false
	player.is_hidden = true

	# Vignette ON
	if vignette:
		vignette.visible = true

# INPUT GLOBAL PRA SAIR
func _unhandled_input(event: InputEvent) -> void:
	if hidden_player == null:
		return

	if event.is_action_pressed("interact"):
		unhide_player()

# SAIR
func unhide_player() -> void:
	if hidden_player == null:
		return

	var player = hidden_player
	
	print("Player saiu do esconderijo")

	# Teleporte saída
	if exit_position:
		player.global_transform = exit_position.global_transform

	# Restaura câmera
	if player_camera:
		player_camera.distance = original_distance
		player_camera.height = original_height
		player_camera.rotation_speed = original_rotation_speed

	# REATIVA PLAYER
	player.input_enabled = true
	player.set_physics_process(true)

	player.set_collision_layer(1)
	player.set_collision_mask(1)

	player.visible = true
	player.is_hidden = false

	# Vignette OFF
	if vignette:
		vignette.visible = false

	hidden_player = null
