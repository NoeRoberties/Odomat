extends Enemy
class_name Beetle

const BEETLE_SPEED: float = 75.0
const BEETLE_HEALTH: int = 10
const HEALTH_BAR_POSITION: Vector2 = Vector2(-24.0, -44.0)
const WANDERING_DISTANCE: float = 300.0
const ATTACK_SPEED_MULTIPLIER: float = 10.0
const ATTACK_DAMAGE: int = 12
const ATTACK_KNOCKBACK_FORCE: float = 260.0
const KNOCKBACK_DEGRESION_FORCE: float = 200.0
const KNOCKBACK_VELOCITY_TRESHOLD: float = 10.0
const DETECTION_AREA_RADIUS: float = 350.0
const RECOVERING_TIME: float = 2.0

var _speed: float = BEETLE_SPEED

var _wandering_destination: Vector2
var _attacking_destination: Vector2
var _player: CharacterBody2D = null
var _attack_timer: Timer = null
var _recover_timer: Timer = null

enum State {ATTACKING, WANDERING, LOADING, KNOCKBACKED, RECOVERING}

var _state: State = State.WANDERING

func _on_ready() -> void:
	_attack_timer = %AttackLoadingTimer
	_recover_timer = %RecoveringTimer
	_health = BEETLE_HEALTH
	_choose_wandering_destination()
	%DetectionCircle.shape.radius = DETECTION_AREA_RADIUS


func _on_physics_process(_delta: float) -> void:
	if _state == State.WANDERING:
		_animated_sprite.play("wandering")
		_animated_sprite.flip_h = velocity.x > 0
		_wander()
	if _state == State.ATTACKING:
		_animated_sprite.play("rush")
		_animated_sprite.flip_h = velocity.x > 0
		_attack()
	if _state == State.KNOCKBACKED:
		velocity = velocity.move_toward(Vector2.ZERO, KNOCKBACK_DEGRESION_FORCE * _delta)
		move_and_slide()
		if velocity.length() <= KNOCKBACK_VELOCITY_TRESHOLD:
			_state = State.WANDERING
	if _state == State.RECOVERING:
		_animated_sprite.play("recovering")
	_handle_collision()


func _on_damage(damage: int, attacker_position: Vector2, knockback_force: float) -> void:
	if knockback_force > 0 and attacker_position != Vector2.ZERO:
		var kb_dir := (global_position - attacker_position)
		if kb_dir.length_squared() == 0.0:
			kb_dir = Vector2.RIGHT
		else:
			kb_dir = kb_dir.normalized()
		velocity = kb_dir * knockback_force
		_state = State.KNOCKBACKED
		if _attack_timer != null:
			_attack_timer.stop()
		_animated_sprite.animation = "hurt"


func _place_health_bar() -> void:
	_health_bar.position = HEALTH_BAR_POSITION


func _load_attack() -> void:
	velocity = Vector2.ZERO
	_state = State.LOADING
	_animated_sprite.play("player_detected")
	if _attack_timer != null:
		_attack_timer.start()


func _attack() -> void:
	var direction: Vector2 = _attacking_destination - global_position
	var distance: float = direction.length()

	if distance > 3.0:
		var attack_speed = _speed * ATTACK_SPEED_MULTIPLIER

		# Slow down when approaching the destination.
		attack_speed = min(attack_speed, distance / get_physics_process_delta_time())

		velocity = direction.normalized() * attack_speed
		move_and_slide()
	else:
		_recover()


func _recover() -> void:
	velocity = Vector2.ZERO
	_state = State.RECOVERING
	_animated_sprite.play("recovering")
	if _recover_timer != null:
		_recover_timer.start(RECOVERING_TIME)


func _wander() -> void:
	
	if _player != null:
		_load_attack()
		
	var direction: Vector2 = _wandering_destination - global_position
	
	if direction.length() > 5.0:
		velocity = direction.normalized() * _speed
	else:
		velocity = Vector2.ZERO
		_choose_wandering_destination()
	move_and_slide()


func _choose_wandering_destination() -> void:
	var angle: float = randf() * TAU
	var offset_vector: Vector2 = Vector2(cos(angle), sin(angle)) * WANDERING_DISTANCE
	
	_wandering_destination = global_position + offset_vector


func _handle_collision() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if _state == State.ATTACKING and (collider as Node).is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(ATTACK_DAMAGE, global_position, ATTACK_KNOCKBACK_FORCE)
			_recover()
			break
		_choose_wandering_destination()


func _on_attack_loading_timer_timeout() -> void:
	_state = State.ATTACKING
	_attacking_destination = _player.global_position
	if _attack_timer != null:
		_attack_timer.stop()


func _on_recovering_timer_timeout() -> void:
	if _player != null:
		_load_attack()
	else:
		_choose_wandering_destination()
		_state = State.WANDERING
	if _attack_timer != null:
		_recover_timer.stop()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = null
		if _attack_timer != null:
			_attack_timer.stop()
		_state = State.WANDERING
		_choose_wandering_destination()
