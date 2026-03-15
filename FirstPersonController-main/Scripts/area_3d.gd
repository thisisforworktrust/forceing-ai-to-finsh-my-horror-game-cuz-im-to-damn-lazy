extends Area3D

@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var required_task: String = "move_box"
@export var complete_task: String = "reach_stairs"

var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:

	if triggered:
		return

	if not body is CharacterBody3D:
		return

	if not TaskManager.is_done(required_task):
		return

	triggered = true

	if sound:
		sound.play()

	TaskManager.complete(complete_task)
	TaskManager.set_objective("Find out what made that crash")
