extends CharacterBody3D

enum EnemyState {
	IDLE,
	WANDER,
	SUSPICIOUS,
	CHASE,
	SEARCH
}

@export var player_path: NodePath = NodePath("../Player")
@export var move_speed: float = 2.25
@export var suspicious_speed: float = 1.8
@export var wander_move_speed: float = 1.25
@export var rotation_speed: float = 5.0
@export var stop_distance: float = 1.8
@export var catch_distance: float = 1.3
@export var gravity: float = 18.0
@export var floor_snap: float = 0.45

@export var vision_distance: float = 20.0
@export_range(10.0, 180.0, 1.0) var vision_angle_degrees: float = 85.0
@export var hearing_radius: float = 10.0

@export var suspicious_investigate_time: float = 2.0
@export var search_time: float = 6.0
@export var wander_direction_change_interval: Vector2 = Vector2(1.2, 3.2)

@export var avoidance_check_distance: float = 1.5
@export var side_probe_offset: float = 0.7

@onready var player: Node3D = get_node_or_null(player_path)

var _state: EnemyState = EnemyState.IDLE
var _last_known_player_position: Vector3 = Vector3.ZERO
var _state_timer: float = 0.0
var _wander_direction: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0

func _ready() -> void:
	floor_snap_length = floor_snap
	_set_new_wander_direction()
	_state = EnemyState.WANDER
	set_physics_process(player != null)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var sees_player := _can_see_player()
	var hears_player := _can_hear_player()

	if sees_player:
		_last_known_player_position = player.global_position
		_set_state(EnemyState.CHASE)
	elif _state == EnemyState.CHASE:
		_begin_search()
	elif hears_player and _state != EnemyState.SEARCH:
		_last_known_player_position = player.global_position
		_set_state(EnemyState.SUSPICIOUS, suspicious_investigate_time)

	if _distance_to_player() <= catch_distance:
		if player.has_method("on_player_caught"):
			player.on_player_caught()
		_set_state(EnemyState.IDLE)
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var move_target := global_position
	var active_speed := 0.0

	match _state:
		EnemyState.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0

		EnemyState.WANDER:
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_set_new_wander_direction()
			move_target = global_position + _wander_direction
			active_speed = wander_move_speed

		EnemyState.SUSPICIOUS:
			_state_timer -= delta
			move_target = _last_known_player_position
			active_speed = suspicious_speed
			if _is_near_position(_last_known_player_position, 1.2) or _state_timer <= 0.0:
				_begin_search()

		EnemyState.CHASE:
			move_target = player.global_position
			active_speed = move_speed
			if _distance_to_player() <= stop_distance:
				velocity.x = 0.0
				velocity.z = 0.0
				move_and_slide()
				return

		EnemyState.SEARCH:
			_state_timer -= delta
			move_target = _last_known_player_position
			active_speed = suspicious_speed
			if _is_near_position(_last_known_player_position, 1.2):
				_set_new_wander_direction()
				move_target = global_position + _wander_direction
				active_speed = wander_move_speed
			if _state_timer <= 0.0:
				_set_state(EnemyState.WANDER)

	if active_speed > 0.0:
		var target_direction := (move_target - global_position)
		target_direction.y = 0.0
		if target_direction.length() > 0.01:
			var move_direction := _get_steering_direction(target_direction.normalized())
			velocity.x = move_direction.x * active_speed
			velocity.z = move_direction.z * active_speed
			var target_basis := Basis.looking_at(move_direction, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)

	move_and_slide()

func _set_state(new_state: EnemyState, timer: float = 0.0) -> void:
	if _state == new_state and timer <= 0.0:
		return
	_state = new_state
	_state_timer = timer

func _begin_search() -> void:
	_set_state(EnemyState.SEARCH, search_time)

func _distance_to_player() -> float:
	var delta := player.global_position - global_position
	delta.y = 0.0
	return delta.length()

func _set_new_wander_direction() -> void:
	_wander_timer = randf_range(wander_direction_change_interval.x, wander_direction_change_interval.y)
	var angle := randf_range(0.0, TAU)
	_wander_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()

func _can_hear_player() -> bool:
	if not player.has_method("get_noise_level"):
		return false
	var noise_level: float = player.get_noise_level()
	if noise_level <= 0.0:
		return false

	var hearing_distance := hearing_radius * noise_level
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length() <= hearing_distance

func _can_see_player() -> bool:
	var eye_position := global_position + Vector3.UP * 1.4
	var player_eye := player.global_position + Vector3.UP * 1.4
	var to_player := player_eye - eye_position
	var distance := to_player.length()

	if distance > vision_distance or distance <= 0.01:
		return false

	var forward := -global_transform.basis.z
	var direction := to_player / distance
	var fov_dot := cos(deg_to_rad(vision_angle_degrees) * 0.5)
	if forward.dot(direction) < fov_dot:
		return false

	var query := PhysicsRayQueryParameters3D.create(eye_position, player_eye)
	query.collide_with_areas = false
	query.exclude = [self]
	var result := get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		return true

	var collider: Object = result.get("collider")
	if collider == player:
		return true
	if collider is Node:
		return player.is_ancestor_of(collider as Node)
	return false

func _is_near_position(target_position: Vector3, radius: float) -> bool:
	var delta := target_position - global_position
	delta.y = 0.0
	return delta.length() <= radius

func _get_steering_direction(chase_direction: Vector3) -> Vector3:
	if not _is_obstacle_ahead(chase_direction, global_position):
		return chase_direction

	var left_direction := chase_direction.rotated(Vector3.UP, deg_to_rad(40.0)).normalized()
	var right_direction := chase_direction.rotated(Vector3.UP, deg_to_rad(-40.0)).normalized()

	var left_origin := global_position - global_transform.basis.x * side_probe_offset
	var right_origin := global_position + global_transform.basis.x * side_probe_offset

	var left_blocked := _is_obstacle_ahead(left_direction, left_origin)
	var right_blocked := _is_obstacle_ahead(right_direction, right_origin)

	if not left_blocked and right_blocked:
		return left_direction
	if not right_blocked and left_blocked:
		return right_direction
	if not left_blocked and not right_blocked:
		if left_direction.dot(chase_direction) > right_direction.dot(chase_direction):
			return left_direction
		return right_direction

	return right_direction

func _is_obstacle_ahead(direction: Vector3, start_position: Vector3) -> bool:
	var origin := start_position + Vector3.UP * 0.9
	var target := origin + direction * avoidance_check_distance

	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collide_with_areas = false
	query.exclude = [self]

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty()
