extends "res://Scripts/interactable.gd"

@onready var anim: AnimationPlayer = $AnimationPlayer
var opened: bool = false

func get_interaction_prompt() -> String:
	return "Press E to interact"

func interact(interactor: Node = null) -> void:
	if not opened:
		if interactor == null or not interactor.has_method("has_key_id") or not interactor.has_key_id("front_key"):
			if interactor and interactor.has_method("show_status_message"):
				interactor.show_status_message("Door is locked. Need the front key.", 2.0)
			if interactor and interactor.has_method("set_objective_text"):
				interactor.set_objective_text("Find the front door key")
			return

		if interactor and interactor.has_method("has_key_id") and (not interactor.has_key_id("red_key") or not interactor.has_key_id("blue_key")):
			if interactor.has_method("show_status_message"):
				interactor.show_status_message("Need red + blue keys objective first.", 2.0)
			if interactor.has_method("set_objective_text"):
				interactor.set_objective_text("Find red and blue keys")
			return

		anim.play("Door_Open")
		opened = true
		if interactor and interactor.has_method("show_status_message"):
			interactor.show_status_message("Door unlocked", 2.0)
		if interactor and interactor.has_method("on_player_escaped"):
			interactor.on_player_escaped()
		return

	anim.play("Door_Close")
	opened = false
