extends Enemy
class_name Beetle

const BEETLE_HEALTH: int = 10

const WANDERING_DISTANCE: float = 200.0
const ATTACK_SPEED_MULTIPLIER: float = 3.0
const ATTACK_DAMAGE: int = 12
const ATTACK_KNOCKBACK_FORCE: float = 260.0

@export var _speed: float = 75.0

var _wandering_destination: Vector2
var _attacking_destination: Vector2
var _player: CharacterBody2D = null

enum State {ATTACKING, WANDERING, LOADING}

var _state: State = State.WANDERING

func _on_ready() -> void:
	_health = BEETLE_HEALTH
	_choose_wandering_destination()


func _on_physics_process(_delta: float) -> void:
	print("This is called")
	if _state == State.WANDERING:
		_animated_sprite.play("wandering")
		_animated_sprite.flip_h = velocity.x > 0
		_wander()
	if _state == State.ATTACKING:
		_animated_sprite.play("rush")
		_animated_sprite.flip_h = velocity.x > 0
		_attack()


func _on_damage(damage: int, attacker_position: Vector2, knockback_force: float) -> void:
	if knockback_force > 0 and attacker_position != Vector2.ZERO:
		var kb_dir := (global_position - attacker_position)
		if kb_dir.length_squared() == 0.0:
			kb_dir = Vector2.RIGHT
		else:
			kb_dir = kb_dir.normalized()
		velocity = kb_dir * knockback_force


func _load_attack() -> void:
	velocity = Vector2.ZERO
	_state = State.LOADING
	_animated_sprite.play("player_detected")
	%AttackLoadingTimer.start()


func _attack() -> void:
	var direction: Vector2 = _attacking_destination - global_position
	
	if direction.length() > 3.0:
		velocity = direction.normalized() * _speed * ATTACK_SPEED_MULTIPLIER
	else:
		_load_attack()
	move_and_slide()
	_apply_contact_damage_to_player()


func _apply_contact_damage_to_player() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if not (collider is Node):
			continue
		if not (collider as Node).is_in_group("player"):
			continue
		if not collider.has_method("take_damage"):
			continue

		# Pass attacker position and force to allow target to compute knockback.
		collider.take_damage(ATTACK_DAMAGE, global_position, ATTACK_KNOCKBACK_FORCE)
		_load_attack()
		break

func _wander() -> void:
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


func _on_attack_loading_timer_timeout() -> void:
	_state = State.ATTACKING
	_attacking_destination = _player.global_position
	%AttackLoadingTimer.stop()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_load_attack()


func _on_detection_area_body_exited(body: Node2D) -> void:
	if _health <= 0:
		return
	if body.is_in_group("player"):
		_player = null
		_state = State.WANDERING
		%AttackLoadingTimer.stop()
		_choose_wandering_destination()
