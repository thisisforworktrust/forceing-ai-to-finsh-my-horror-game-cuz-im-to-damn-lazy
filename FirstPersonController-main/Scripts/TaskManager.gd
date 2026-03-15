extends Node

signal objective_changed(text: String)
signal game_state_changed(state: String, message: String)

var completed_tasks: Dictionary = {}
var current_objective: String = ""
var game_state: String = "playing"
var game_message: String = ""

const MENU_SCENE := "res://Scenes/main_menu.tscn"

func reset_progress() -> void:
	completed_tasks.clear()
	game_state = "playing"
	game_message = ""
	set_objective("")
	game_state_changed.emit(game_state, game_message)

func complete(task_name: String) -> void:
	completed_tasks[task_name] = true

func is_done(task_name: String) -> bool:
	return completed_tasks.has(task_name)

func set_objective(text: String) -> void:
	if game_state != "playing":
		return
	current_objective = text
	objective_changed.emit(text)

func win_game(message: String = "You escaped.") -> void:
	if game_state != "playing":
		return
	game_state = "win"
	game_message = message
	game_state_changed.emit(game_state, game_message)
	_end_run()

func lose_game(message: String = "You were caught.") -> void:
	if game_state != "playing":
		return
	game_state = "lose"
	game_message = message
	game_state_changed.emit(game_state, game_message)
	_end_run()

func _end_run() -> void:
	await get_tree().create_timer(3.0).timeout
	reset_progress()
	get_tree().change_scene_to_file(MENU_SCENE)
