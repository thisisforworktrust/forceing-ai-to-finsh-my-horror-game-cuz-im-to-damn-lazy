extends "res://Scripts/interactable.gd"

@onready var anim: AnimationPlayer = $AnimationPlayer

var triggered: bool = false

func interact(interactor: Node = null) -> void:
	if triggered:
		return

	triggered = true

	if anim:
		anim.play("Move")

	if interactor and interactor.has_method("set_objective_text"):
		interactor.set_objective_text("You made noise. Stay out of sight")
	if interactor and interactor.has_method("show_status_message"):
		interactor.show_status_message("That noise might attract Bag Man", 2.5)
