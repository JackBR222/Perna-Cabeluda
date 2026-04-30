extends Node3D

@export var open_scene: PackedScene  # Prefab do portão aberto

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var is_opening: bool = false
var is_open: bool = false


func _ready():
	_set_closed_pose()
	Dialogic.signal_event.connect(_on_dialogic_signal)


	#await get_tree().create_timer(1.0).timeout
	#open_gate()


# FUNÇÕES EXTERNAS
func open_gate():
	if is_open or is_opening:
		return

	is_opening = true

	anim_player.play("Armature|OPEN GATE_001")

	if not anim_player.animation_finished.is_connected(_on_anim_finished):
		anim_player.animation_finished.connect(_on_anim_finished)


func force_close():
	is_opening = false
	is_open = false
	_set_closed_pose()


# INTERNO
func _set_closed_pose():
	anim_player.stop()

	# garante que o primeiro frame da animação seja aplicado e “travado”
	anim_player.play("Armature|OPEN GATE_001")
	anim_player.seek(0.0, true)
	anim_player.stop()

	# reforça que o pose do frame 0 fica aplicado
	anim_player.advance(0)


func _on_anim_finished(anim_name: StringName):
	if anim_name == "Armature|OPEN GATE_001":
		_finish_opening()


func _finish_opening():
	is_opening = false
	is_open = true

	if open_scene:
		var opened_gate = open_scene.instantiate()
		get_parent().add_child(opened_gate)
		opened_gate.global_transform = global_transform

	queue_free()
	
func _on_dialogic_signal(argument: String) -> void:

		if argument == "open_gate":
			open_gate()
