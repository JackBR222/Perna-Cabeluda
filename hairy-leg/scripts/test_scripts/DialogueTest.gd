extends StaticBody3D

var current_player: Player = null

func interact(player: Node) -> void:
	if not player is Player:
		return
	
	current_player = player as Player
	start_dialog()

func start_dialog() -> void:
	if current_player:
		current_player.input_enabled = false
	
	# Conecta ao sinal global do Dialogic
	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start("test")

func _on_timeline_ended() -> void:
	# Desconecta pra evitar múltiplas conexões
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	
	# Reativa o input
	if current_player:
		current_player.input_enabled = true
		current_player = null
