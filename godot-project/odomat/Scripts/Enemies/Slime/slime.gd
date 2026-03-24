extends CharacterBody2D
class_name Slime

@export var _health: float = 10.0
@export var _speed: float = 100.0

var _alive: bool = true
var _state: State = State.WANDERING
var _animated_sprite: AnimatedSprite2D
var _wandering_destination: Vector2
var _attacking_destination: Vector2
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
		velocity = direction.normalized() * _speed * 2
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
	var distance: float = 50.0
	var angle: float = randf() * TAU
	var offset_vector: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	
	_wandering_destination = global_position + offset_vector


# To replace later with the player body
func _on_detection_area_mouse_entered() -> void:
	_load_attack()


# To replace later with the player body
func _on_detection_area_mouse_exited() -> void:
	_state = State.WANDERING
	%AttackLoadingTimer.stop()
	_choose_wandering_destination()


func _on_attack_loading_timer_timeout() -> void:
	_state = State.ATTACKING
	_attacking_destination = get_global_mouse_position()
	%AttackLoadingTimer.stop()
