extends Area3D

var in_trigger = false

@onready var camera: Camera3D = get_parent().get_node("Camera3D")

func enter_trigger(body):
	if body.name == "Player":
		in_trigger = true

func exit_trigger(body):
	if body.name == "Player":
		in_trigger = false

func _process(_delta: float) -> void:
	if in_trigger and camera.current != true:
		camera.current = true


func _on_body_entered(body: Node3D) -> void:
	enter_trigger(body)


func _on_body_exited(body: Node3D) -> void:
	exit_trigger(body)
