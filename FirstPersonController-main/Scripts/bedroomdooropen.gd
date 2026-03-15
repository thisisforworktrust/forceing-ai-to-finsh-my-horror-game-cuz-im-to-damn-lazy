extends "res://Scripts/interactable.gd"

@onready var anim: AnimationPlayer = $AnimationPlayer
var opened: bool = false

func get_interaction_prompt() -> String:
	return "Press E to interact"

func interact(interactor: Node = null) -> void:
	if not opened:
		if interactor == null or not interactor.has_method("has_key_id"):
			return

		var has_red := interactor.has_key_id("red_key")
		var has_blue := interactor.has_key_id("blue_key")
		if not has_red or not has_blue:
			if interactor.has_method("show_status_message"):
				interactor.show_status_message("Need BOTH keys: red + blue", 2.2)
			if interactor.has_method("set_objective_text"):
				interactor.set_objective_text("Find red and blue keys")
			return

		anim.play("Door_Open")
		opened = true
		if interactor.has_method("on_dual_door_unlocked"):
			interactor.on_dual_door_unlocked()
		return

	anim.play("Door_Close")
	opened = false
