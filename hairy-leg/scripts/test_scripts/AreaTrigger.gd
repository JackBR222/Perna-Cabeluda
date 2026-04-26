extends Area3D

# Referências diretas
@onready var player = get_tree().current_scene.get_node("Player/Player")
@onready var enemy = get_tree().current_scene.get_node("Enemy")

# Grupo de patrulha que o inimigo deve mudar
@export var patrol_group_to_set: int = 1

# READY
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

# DETECÇÃO DE ENTRADA
func _on_body_entered(body: Node) -> void:
	# checa referências válidas
	if not player or not enemy:
		return

	# Só reage se o player entrou
	if body != player:
		return

	# Certifica que o inimigo tem o método 'set_patrol_group'
	if not enemy.has_method("set_patrol_group"):
		print("O inimigo não possui o método 'set_patrol_group'!")
		return

	# Ignora se o inimigo já está na mesma rota
	var current_group = enemy.get("current_patrol_group_number")
	if current_group == patrol_group_to_set:
		return

	# Muda a rota
	enemy.set_patrol_group(patrol_group_to_set)
	print("Inimigo mudou para o grupo de patrulha:", patrol_group_to_set)
