extends RigidBody3D
class_name Item

@export var item_type: String = "generic"
@export var hold_offset: Vector3 = Vector3(0.35, -0.35, -0.9)
@export var hold_rotation: Vector3 = Vector3(-15, 45, 0)

var is_being_held: bool = false
var original_position: Vector3
var original_rotation: Vector3


func _ready() -> void:
	original_position = global_position
	original_rotation = global_rotation
	freeze = true


# =========================
# INTERAÇÃO PRINCIPAL
# =========================
func interact(player: Node) -> void:
	if not player is Player:
		return

	# Pega item
	if player.held_item == null:
		_pick_up(player)
		_update_dialogic(player)

	# Troca item
	elif player.held_item != self:
		_swap_with_player(player)
		_update_dialogic(player)


# =========================
# PEGAR ITEM
# =========================
func _pick_up(player: Player) -> void:
	is_being_held = true
	freeze = true

	player.held_item = self

	reparent(player.hold_position)

	global_position = player.hold_position.global_position + player.hold_position.global_transform.basis * hold_offset
	global_rotation = player.hold_position.global_rotation + hold_rotation * PI / 180.0


# =========================
# SOLTAR ITEM
# =========================
func put_down(target_position: Vector3, target_rotation: Vector3 = Vector3.ZERO) -> void:
	is_being_held = false

	reparent(get_tree().current_scene)

	global_position = target_position

	if target_rotation == Vector3.ZERO:
		global_rotation = original_rotation
	else:
		global_rotation = target_rotation

	freeze = true


# =========================
# TROCA COM PLAYER
# =========================
func _swap_with_player(player: Player) -> void:
	var current_item = player.held_item
	if current_item == self:
		return

	var swap_pos = global_position
	var swap_rot = global_rotation

	current_item.put_down(swap_pos, swap_rot)

	player.held_item = null
	_pick_up(player)


# =========================
# CONSUMIR ITEM (ex: chave)
# =========================
func consume() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player and player.held_item == self:
		player.held_item = null
		_update_dialogic(player)

	queue_free()


# =========================
# DIALOGIC INTEGRATION
# =========================
func _update_dialogic(player: Player) -> void:
	if player.held_item == null:
		Dialogic.VAR.set("player_item_type", "none")
	else:
		Dialogic.VAR.set("player_item_type", player.held_item.item_type)
