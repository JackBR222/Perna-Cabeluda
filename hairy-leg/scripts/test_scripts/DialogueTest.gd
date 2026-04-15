extends StaticBody3D

var current_player: Player = null


# =========================
# INTERAÇÃO
# =========================
func interact(player: Node) -> void:
	if not player is Player:
		return

	current_player = player as Player
	start_dialog()


# =========================
# START DIALOG
# =========================
func start_dialog() -> void:
	if current_player:
		current_player.freeze_input()  # ✔ AGORA USA O PLAYER SYSTEM

	# evita múltiplas conexões
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	Dialogic.timeline_ended.connect(_on_timeline_ended)

	Dialogic.start("test")


# =========================
# END DIALOG
# =========================
func _on_timeline_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	if current_player:
		current_player.unfreeze_input()  # ✔ AGORA USA O PLAYER SYSTEM
		current_player = null
