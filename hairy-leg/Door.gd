extends StaticBody3D
class_name Door

# Configurações da porta
@export var required_item_type: String = "key"       # Tipo de item necessário
@export var open_rotation: Vector3 = Vector3(0, 90, 0)
@export var closed_rotation: Vector3 = Vector3.ZERO

var is_open: bool = false
var door_mesh: MeshInstance3D
var collision_shape: CollisionShape3D

# Setup automático
func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			door_mesh = child
		elif child is CollisionShape3D:
			collision_shape = child
	
	if door_mesh:
		door_mesh.rotation_degrees = closed_rotation
	
	if not collision_shape:
		push_warning("Porta precisa de CollisionShape3D para ser detectável pelo RayCast do Player!")

# Interação chamada pelo Player
func interact(player: Node) -> void:
	if not player is Player:
		return

	if is_open:
		print("Porta já está aberta")
		return

	if player.held_item == null:
		print("Você não está segurando nenhum item")
		return

	if player.held_item.item_type == required_item_type:
		open()
	else:
		print("Item incorreto para esta porta")

# Abrir porta
func open() -> void:
	is_open = true
	print("Porta abriu!")
	if door_mesh:
		door_mesh.rotation_degrees = open_rotation
	if collision_shape:
		collision_shape.disabled = true
