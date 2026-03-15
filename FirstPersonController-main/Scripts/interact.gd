extends "res://Scripts/Player.gd"

@onready var ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var interaction_label: Label = $"../CanvasLayer/InteractionLabel"
@onready var objective_label: Label = $"../CanvasLayer/ObjectiveLabel"
@onready var state_label: Label = $"../CanvasLayer/StateLabel"

var has_key: bool = false
var game_over: bool = false
var escaped: bool = false
var _status_timer: float = 0.0
var _keys: Dictionary = {}
var _dual_door_unlocked: bool = false

func _ready() -> void:
	super._ready()
	_update_interaction_label("")
	_set_objective("Find the front door key")
	_show_state_message("Find keys and escape", 3.0)

func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0 and not game_over and not escaped:
			_show_state_message("")

	if game_over or escaped:
		_update_interaction_label("")
		return

	var collider := _get_interactable_collider()

	if collider:
		if collider.has_method("get_interaction_prompt"):
			_update_interaction_label(collider.get_interaction_prompt())
		else:
			_update_interaction_label("Press E to interact")
	else:
		_update_interaction_label("")

	if collider and Input.is_action_just_pressed("interact"):
		collider.interact(self)

func is_player_locked() -> bool:
	return game_over or escaped

func _get_interactable_collider() -> Node:
	if not ray.is_colliding():
		return null

	var collider = ray.get_collider()
	if collider and collider.has_method("interact"):
		return collider

	return null

func _update_interaction_label(text: String) -> void:
	if interaction_label:
		interaction_label.text = text

func _set_objective(text: String) -> void:
	if objective_label:
		objective_label.text = text

func show_status_message(text: String, duration: float = 2.2) -> void:
	_show_state_message(text, duration)

func set_objective_text(text: String) -> void:
	_set_objective(text)

func _show_state_message(text: String, duration: float = 0.0) -> void:
	if state_label:
		state_label.text = text
	_status_timer = duration

func add_key(key_id: String, display_name: String = "Key") -> void:
	_keys[key_id] = true
	if key_id == "front_key":
		has_key = true
	if display_name != "":
		show_status_message("Picked up: %s" % display_name, 2.0)
	_update_objective_from_progress()

func has_key_id(key_id: String) -> bool:
	return bool(_keys.get(key_id, false))

func _update_objective_from_progress() -> void:
	if escaped:
		_set_objective("Escaped")
		return

	if not has_key_id("front_key"):
		_set_objective("Find the front door key")
		return

	if not _dual_door_unlocked:
		if has_key_id("red_key") and has_key_id("blue_key"):
			_set_objective("Find the red-blue locked door")
		else:
			_set_objective("Find red and blue keys")
		return

	_set_objective("Reach the front door and escape")

func give_key() -> void:
	add_key("front_key", "Front Door Key")

func on_dual_door_unlocked() -> void:
	_dual_door_unlocked = true
	show_status_message("Door unlocked with red + blue keys", 2.4)
	_update_objective_from_progress()

func on_player_caught() -> void:
	if game_over or escaped:
		return
	game_over = true
	_set_objective("You were caught")
	_show_state_message("CAUGHT - press R to restart")

func on_player_escaped() -> void:
	if game_over or escaped:
		return
	escaped = true
	_set_objective("Escaped")
	_show_state_message("YOU ESCAPED", 0.0)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
