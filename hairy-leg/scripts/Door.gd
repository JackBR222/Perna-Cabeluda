extends StaticBody3D
class_name Door

@export var required_item_type: String = "key"

var current_player: Player = null
var is_open: bool = false


# =========================
# INTERAÇÃO
# =========================
func interact(player: Node) -> void:
	if not player is Player:
		return

	# ❌ bloqueia interação se já estiver aberta
	if is_open:
		return

	current_player = player

	_update_dialogic_variables(player)
	start_dialog()


# =========================
# START DIALOG
# =========================
func start_dialog() -> void:
	if current_player:
		current_player.input_enabled = false

	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	Dialogic.timeline_ended.connect(_on_timeline_ended)

	Dialogic.start("testDoor")


# =========================
# FINAL DO DIALOGO
# =========================
func _on_timeline_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	if current_player:
		current_player.input_enabled = true

		var item = current_player.held_item

		# ✔ abre porta somente uma vez
		if item != null and item.item_type == required_item_type:
			_open_door(current_player)

	current_player = null


# =========================
# ABRIR PORTA
# =========================
func _open_door(player: Player) -> void:
	is_open = true  # 🔥 bloqueia futuras interações

	var item = player.held_item

	if item != null:
		item.consume()

	# opcional: feedback visual
	print("Porta aberta!")


# =========================
# DIALOGIC VARIABLES
# =========================
func _update_dialogic_variables(player: Player) -> void:
	if not Engine.has_singleton("Dialogic"):
		return

	if player.held_item == null:
		Dialogic.VAR.set("player_item_type", "none")
	else:
		Dialogic.VAR.set("player_item_type", player.held_item.item_type)

	Dialogic.VAR.set("door_required_item", required_item_type)
