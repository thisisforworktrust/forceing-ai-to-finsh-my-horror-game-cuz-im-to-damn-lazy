extends Label

func _ready() -> void:
	text = "Objective: " + TaskManager.current_objective
	modulate = Color.WHITE
	TaskManager.objective_changed.connect(_on_objective_changed)
	TaskManager.game_state_changed.connect(_on_game_state_changed)

func _on_objective_changed(t: String) -> void:
	text = "Objective: " + t
	modulate = Color.WHITE

func _on_game_state_changed(state: String, message: String) -> void:
	if state == "win":
		text = "YOU ESCAPED\n" + message
		modulate = Color(0.7, 1.0, 0.7)
	elif state == "lose":
		text = "YOU DIED\n" + message
		modulate = Color(1.0, 0.5, 0.5)
	else:
		text = "Objective: " + TaskManager.current_objective
		modulate = Color.WHITE
