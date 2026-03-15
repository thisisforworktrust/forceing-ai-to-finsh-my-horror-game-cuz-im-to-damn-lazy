extends CharacterBody3D

var speed: float
const WALK_SPEED: float = 3.5
const CROUCH_SPEED: float = 2.0
const SPRINT_SPEED: float = 3.5
const JUMP_VELOCITY: float = 0.0
const SENSITIVITY: float = 0.004

# bob variables
const BOB_FREQ: float = 2.4
const BOB_AMP: float = 0.08
var t_bob: float = 0.0

# fov variables
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5

var gravity: float = 9.8
var step_timer: float = 0.0
@export var step_interval: float = 0.45

@export var crouch_height: float = 1.0
@export var stand_height: float = 2.0
@export var crouch_lerp_speed: float = 10.0
@export var stand_lerp_speed: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var footsteps: AudioStreamPlayer3D = $Player/Head/Camera3D/SpotLight3D/Footsteps
@onready var collider: CollisionShape3D = $CollisionShape3D

var _is_crouching: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if collider and collider.shape is CapsuleShape3D:
		stand_height = (collider.shape as CapsuleShape3D).height
		crouch_height = max(stand_height * 0.6, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	if is_player_locked():
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var wants_crouch := _is_crouch_pressed()
	if wants_crouch:
		_is_crouching = true
	elif _can_stand_up():
		_is_crouching = false

	_update_crouch_shape(delta)

	if _is_crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped := clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov := BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50.0)
	move_and_slide()
	_handle_footsteps(delta)

func is_player_locked() -> bool:
	return false

func get_noise_level() -> float:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.05:
		return 0.0
	if _is_crouching:
		return 0.35
	if speed >= SPRINT_SPEED - 0.1:
		return 1.4
	return 1.0

func _headbob(time: float) -> Vector3:
	var pos := Vector3.ZERO
	if _is_crouching:
		pos.y = sin(time * BOB_FREQ) * (BOB_AMP * 0.5)
		pos.x = cos(time * BOB_FREQ / 2.0) * (BOB_AMP * 0.5)
		return pos
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2.0) * BOB_AMP
	return pos

func _handle_footsteps(delta: float) -> void:
	if not is_on_floor():
		step_timer = 0
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < 0.1:
		step_timer = 0
		return

	step_timer -= delta
	if step_timer <= 0.0:
		if footsteps:
			footsteps.play()
		step_timer = step_interval

func _is_crouch_pressed() -> bool:
	if InputMap.has_action("crouch"):
		return Input.is_action_pressed("crouch")
	return Input.is_key_pressed(KEY_CTRL)

func _can_stand_up() -> bool:
	if not collider or not (collider.shape is CapsuleShape3D):
		return true

	var capsule := collider.shape as CapsuleShape3D
	if capsule.height >= stand_height - 0.01:
		return true

	var stand_capsule := CapsuleShape3D.new()
	stand_capsule.radius = capsule.radius
	stand_capsule.height = stand_height

	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = stand_capsule
	shape_query.collide_with_areas = false
	shape_query.collide_with_bodies = true
	shape_query.exclude = [self]

	var extra_height := stand_height - capsule.height
	var stand_transform := collider.global_transform
	stand_transform.origin += Vector3.UP * (extra_height * 0.5)
	shape_query.transform = stand_transform

	var hits := get_world_3d().direct_space_state.intersect_shape(shape_query, 1)
	return hits.is_empty()

func _update_crouch_shape(delta: float) -> void:
	if not collider or not (collider.shape is CapsuleShape3D):
		return

	var capsule := collider.shape as CapsuleShape3D
	var target_height := crouch_height if _is_crouching else stand_height
	var speed_lerp := crouch_lerp_speed if _is_crouching else stand_lerp_speed
	capsule.height = lerp(capsule.height, target_height, delta * speed_lerp)
