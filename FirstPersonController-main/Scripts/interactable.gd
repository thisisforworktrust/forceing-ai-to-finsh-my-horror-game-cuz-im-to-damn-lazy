extends Node3D

@export var interaction_prompt: String = "Press E to interact"

func get_interaction_prompt() -> String:
	return interaction_prompt

func interact(_interactor: Node = null) -> void:
	print("Interacted!")
