extends "res://Scripts/interactable.gd"

@export var key_id: String = "front_key"
@export var key_name: String = "Key"

func get_interaction_prompt() -> String:
	return "Press E to pick up"

func interact(interactor: Node = null) -> void:
	if interactor and interactor.has_method("add_key"):
		interactor.add_key(key_id, key_name)
	queue_free()
