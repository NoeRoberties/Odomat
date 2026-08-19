extends Enemy
class_name Archer

const ARCHER_HEALTH: int = 15

@export var arrow_scene: PackedScene = preload("res://Scenes/Enemies/Archer/Arrow.tscn")

enum State {
	IDLE,
	APPROACH,
	DASH_APPROACH,
	PREPARE_SHOT,
	SHOOT,
	DASH_FLEE,
	KNOCKBACK
}

var _state: State = State.IDLE

var _speed := 90.0
var _shoot_distance := 250.0

var _player: Node2D = null
var _in_attack_zone := false
var _in_danger_zone := false

var _shoot_cooldown := 1.0
var _shoot_timer := 0.0

var _prepare_shot_duration := 1.3
var _prepare_shot_timer := 0.0

var _dash_speed := 320.0
var _dash_duration := 0.22
var _dash_timer := 0.0
var _dash_direction := Vector2.ZERO

var _has_shot := false
var _last_non_zero_flee_direction := Vector2.RIGHT
var _shoot_end_timer := 0.0

var _knockback_velocity := Vector2.ZERO
var _knockback_timer := 0.0
const KNOCKBACK_DURATION := 0.5


func _on_ready() -> void:
	_health = ARCHER_HEALTH


func _on_physics_process(delta: float) -> void:
	if _shoot_timer > 0.0:
		_shoot_timer -= delta

	match _state:
		State.IDLE:
			_state_idle()

		State.APPROACH:
			_state_approach()

		State.DASH_APPROACH:
			_state_dash_approach(delta)

		State.PREPARE_SHOT:
			_state_prepare_shot(delta)

		State.SHOOT:
			_state_shoot(delta)

		State.DASH_FLEE:
			_state_dash_flee(delta)

		State.KNOCKBACK:
			_state_knockback(delta)

	_update_sprite_direction()
	if velocity.length_squared() > 0.0001:
		move_and_slide()


func _on_damage(_damage: int, attacker_position: Vector2, knockback_force: float) -> void:
	if attacker_position != Vector2.ZERO:
		var dir := (global_position - attacker_position).normalized()
		_knockback_velocity = dir * knockback_force
	_knockback_timer = KNOCKBACK_DURATION
	_state = State.KNOCKBACK
	_has_shot = false
	_shoot_end_timer = 0.0


func _state_idle() -> void:
	velocity = Vector2.ZERO
	if _animated_sprite.animation != "idle":
		_animated_sprite.play("idle")

	if _player == null:
		return

	if _in_danger_zone:
		_start_dash_flee()
		return

	if _in_attack_zone:
		var dist = global_position.distance_to(_player.global_position)
		if dist > _shoot_distance:
			_start_dash_approach()
		elif _shoot_timer <= 0.0:
			_start_prepare_shot()


func _state_approach() -> void:
	if _player == null:
		_state = State.IDLE
		velocity = Vector2.ZERO
		return

	if _in_danger_zone:
		_start_dash_flee()
		return

	var dist = global_position.distance_to(_player.global_position)

	if dist <= _shoot_distance:
		velocity = Vector2.ZERO
		if _shoot_timer <= 0.0:
			_start_prepare_shot()
		else:
			_state = State.IDLE
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * _speed
	if _animated_sprite.animation != "walk":
		_animated_sprite.play("walk")


func _state_dash_approach(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * _dash_speed
	if _animated_sprite.animation != "walk":
		_animated_sprite.play("walk")

	if _dash_timer <= 0.0:
		velocity = Vector2.ZERO
		if _player == null:
			_state = State.IDLE
			return

		if _in_danger_zone:
			_start_dash_flee()
			return

		var dist = global_position.distance_to(_player.global_position)
		if dist <= _shoot_distance and _shoot_timer <= 0.0:
			_start_prepare_shot()
		else:
			_state = State.APPROACH


func _state_prepare_shot(delta: float) -> void:
	velocity = Vector2.ZERO
	if _animated_sprite.animation != "idle":
		_animated_sprite.play("idle")

	if _player == null:
		_state = State.IDLE
		return

	if _in_danger_zone:
		_start_dash_flee()
		return

	_prepare_shot_timer -= delta
	if _prepare_shot_timer <= 0.0:
		_state = State.SHOOT


func _state_shoot(delta: float) -> void:
	velocity = Vector2.ZERO

	if _player == null or not arrow_scene:
		_state = State.IDLE
		return

	if not _has_shot:
		_has_shot = true
		_shoot_timer = _shoot_cooldown
		_shoot()

	if _animated_sprite.animation != "shoot":
		_animated_sprite.play("shoot")

	_shoot_end_timer -= delta
	if _shoot_end_timer <= 0.0:
		if _in_danger_zone and _player != null:
			_start_dash_flee()
		else:
			_state = State.IDLE


func _state_dash_flee(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * _dash_speed
	if _animated_sprite.animation != "walk":
		_animated_sprite.play("walk")

	if _dash_timer <= 0.0:
		velocity = Vector2.ZERO

		if _player == null:
			_state = State.IDLE
			return

		if _in_danger_zone:
			_start_dash_flee()
			return

		if _in_attack_zone and _shoot_timer <= 0.0:
			_start_prepare_shot()
		else:
			_state = State.IDLE


func _state_knockback(delta: float) -> void:
	_knockback_timer -= delta
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	velocity = _knockback_velocity

	if _knockback_timer <= 0.0:
		_knockback_velocity = Vector2.ZERO
		velocity = Vector2.ZERO

		if _player != null and _in_danger_zone:
			_start_dash_flee()
		else:
			_state = State.IDLE

		_shoot_timer = _shoot_cooldown


func _start_dash_approach() -> void:
	if _player == null:
		return
	_dash_direction = (_player.global_position - global_position).normalized()
	_dash_timer = _dash_duration
	_state = State.DASH_APPROACH


func _start_dash_flee() -> void:
	if _player == null:
		return
	_dash_direction = _get_flee_direction()
	_dash_timer = _dash_duration
	_state = State.DASH_FLEE


func _start_prepare_shot() -> void:
	_prepare_shot_timer = _prepare_shot_duration
	_has_shot = false
	_shoot_end_timer = 0.0
	_state = State.PREPARE_SHOT


func _get_flee_direction() -> Vector2:
	if _player == null:
		return _last_non_zero_flee_direction

	var dir := global_position - _player.global_position

	if dir.length_squared() > 0.0001:
		_last_non_zero_flee_direction = dir.normalized()
		return _last_non_zero_flee_direction

	if velocity.length_squared() > 0.0001:
		_last_non_zero_flee_direction = velocity.normalized()
		return _last_non_zero_flee_direction

	return _last_non_zero_flee_direction


func _shoot() -> void:
	if not arrow_scene or not _player:
		return

	var target_position = _player.global_position
	_animated_sprite.play("shoot")

	var frame_count: int = _animated_sprite.sprite_frames.get_frame_count("shoot")
	var anim_speed: float = _animated_sprite.sprite_frames.get_animation_speed("shoot")
	var shoot_duration: float = 0.5

	if anim_speed > 0.0:
		shoot_duration = float(frame_count) / anim_speed

	_shoot_end_timer = shoot_duration

	var wait_time: float = shoot_duration - 0.5
	if wait_time < 0.0:
		wait_time = 0.0

	await get_tree().create_timer(wait_time).timeout

	if _state != State.SHOOT or _player == null:
		return

	var offset = Vector2(5, -30)
	if _animated_sprite.flip_h:
		offset.x = -offset.x

	var shoot_pos = global_position + offset
	var arrow = arrow_scene.instantiate()
	arrow.pos = shoot_pos
	arrow.dir = (target_position - shoot_pos).angle()
	arrow.rota = arrow.dir
	arrow.target = _player
	get_tree().current_scene.add_child(arrow)


func _on_animated_sprite_2d_animation_finished() -> void:
	if _animated_sprite.animation != "shoot":
		return

	if _state != State.SHOOT:
		return

	if _in_danger_zone and _player != null:
		_start_dash_flee()
	else:
		_state = State.IDLE


func _update_sprite_direction() -> void:
	if _player == null:
		return

	if _state == State.DASH_FLEE:
		_animated_sprite.flip_h = (_player.global_position.x > global_position.x)
	else:
		_animated_sprite.flip_h = (_player.global_position.x < global_position.x)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_in_attack_zone = true
	_shoot_timer = _shoot_cooldown

	if _in_danger_zone and _state != State.SHOOT and _state != State.KNOCKBACK:
		_start_dash_flee()


func _on_attack_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_attack_zone = false
	if not _in_danger_zone:
		_player = null
		_state = State.IDLE
		velocity = Vector2.ZERO


func _on_danger_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_in_danger_zone = true

	if _state != State.SHOOT and _state != State.KNOCKBACK:
		_start_dash_flee()


func _on_danger_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_danger_zone = false
	if not _in_attack_zone:
		_player = null
		_state = State.IDLE
		velocity = Vector2.ZERO
