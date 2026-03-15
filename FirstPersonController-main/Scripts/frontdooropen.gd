extends "res://Scripts/interactable.gd"

@onready var anim: AnimationPlayer = $AnimationPlayer
var opened := false

func interact() -> void:
	if TaskManager.game_state != "playing":
		return

	if not TaskManager.is_done("reach_stairs"):
		TaskManager.set_objective("Something feels wrong upstairs first")
		return

	if not TaskManager.is_done("inspect_crash"):
		TaskManager.set_objective("Find out what crashed upstairs")
		return

	if opened:
		anim.play("Door_Close")
	else:
		anim.play("Door_Open")
		TaskManager.win_game("You escaped the house.")

	opened = !opened
