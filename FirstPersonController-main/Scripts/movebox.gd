extends "res://Scripts/interactable.gd"

@onready var anim: AnimationPlayer = $AnimationPlayer

var triggered: bool = false

func interact() -> void:

	if triggered:
		return

	triggered = true

	if anim:
		anim.play("Move")

	TaskManager.complete("move_box")
	TaskManager.set_objective("Go check upstairs")
