extends Area3D

@onready var anim = $"../Armature/AnimationPlayer"
@onready var sound = $AudioStreamPlayer3D

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	triggered = false

func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if not body is CharacterBody3D:
		return

	triggered = true
	if sound:
		sound.play()
	if anim:
		anim.play("Attack")

	TaskManager.lose_game("The bag man got you.")
