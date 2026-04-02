extends StaticBody3D
class_name HideSpot

# NODES
@export var exit_position: Node3D
@export var hide_camera: Camera3D

var hidden_player: Player = null
var player_camera: Camera3D = null

# INTERAÇÃO
func interact(player: Node) -> void:
	if not player is Player:
		return

	if hidden_player != null:
		unhide_player()
	else:
		hide_player(player)


# ESCONDER
func hide_player(player: Player) -> void:
	hidden_player = player
	
	print("Player se escondeu")

	# Guarda a câmera do player
	player_camera = player.get_node_or_null("Camera3D")

	# Desativa câmera do player
	if player_camera:
		player_camera.current = false

	# Ativa câmera do esconderijo
	if hide_camera:
		hide_camera.current = true

	# Esconde player
	player.visible = false

	# Desativa colisão
	player.set_collision_layer(0)
	player.set_collision_mask(0)

	# Para movimento
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)

	# Flag opcional
	player.is_hidden = true


# SAIR DO ESCONDERIJO
func unhide_player() -> void:
	if hidden_player == null:
		return

	var player = hidden_player

	print("Player saiu do esconderijo")

	# TELEPORTE COMPLETO (posição + rotação)
	if exit_position:
		player.global_transform = exit_position.global_transform

	# Troca câmeras
	if hide_camera:
		hide_camera.current = false

	if player_camera:
		player_camera.current = true

	# Reativa player
	player.visible = true
	player.set_collision_layer(1)
	player.set_collision_mask(1)
	player.set_physics_process(true)

	player.is_hidden = false

	hidden_player = null
