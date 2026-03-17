extends CharacterBody2D
class_name Enemy

enum State {ATTACKING, WANDERING, LOADING}

@export var _health: float = 10.0
@export var _speed: float = 100.0

var _alive: bool = true
var _state: State = State.WANDERING

func _process(_delta: float) -> void:
	if _state == State.WANDERING:
		_wander()
	if _state == State.ATTACKING:
		_attack()

func _take_damage(damage: float) -> void:
	_health -= damage
	if _health <= 0.0:
		_alive = false


func _load_attack() -> void:
	pass


func _attack() -> void:
	pass


func _wander() -> void:
	pass
