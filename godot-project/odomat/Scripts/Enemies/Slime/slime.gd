extends CharacterBody2D
class_name Slime

const WANDERING_DISTANCE: float = 200.0
const ATTACK_SPEED_MULTIPLIER: float = 3.0

@export var _health: float = 10.0
@export var _speed: float = 75.0

var _alive: bool = true
var _state: State = State.WANDERING
var _animated_sprite: AnimatedSprite2D
var _wandering_destination: Vector2
var _attacking_destination: Vector2
var _player: CharacterBody2D = null

enum State {ATTACKING, WANDERING, LOADING}

func _physics_process(delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	if _state == State.WANDERING:
		_wander()
	if _state == State.ATTACKING:
		_attack()

func _ready() -> void:
	_animated_sprite = $AnimatedSprite2D
	_choose_wandering_destination()


func _load_attack() -> void:
	velocity = Vector2.ZERO
	_state = State.LOADING
	%AttackLoadingTimer.start()


func _attack() -> void:
	var direction: Vector2 = _attacking_destination - global_position
	
	if direction.length() > 3.0:
		velocity = direction.normalized() * _speed * ATTACK_SPEED_MULTIPLIER
	else:
		_load_attack()
	move_and_slide()


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
		
func take_damage(damage, knockback_velocity: Vector2 = Vector2.ZERO):
	_health -= damage
	
	# Apply knockback
	if knockback_velocity.length() > 0:
		velocity -= knockback_velocity
	
	# Visual feedback: blinking effect
	if _animated_sprite:
		_animate_blink()
	else:
		print("WARNING: _animated_sprite is null!")
	
	if _health <= 0:
		queue_free()


func _animate_blink() -> void:
	var original_color = _animated_sprite.self_modulate
	var tween = create_tween()
	tween.set_parallel(false)  # Sequential animations
	
	for i in range(1):
		tween.tween_property(_animated_sprite, "self_modulate", Color.RED, 0.08)
		tween.tween_property(_animated_sprite, "self_modulate", original_color, 0.08)
	
