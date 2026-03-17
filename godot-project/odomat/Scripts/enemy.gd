extends CharacterBody2D
class_name Enemy

enum State {ATTACKING, WANDERING, LOADING}

@export var health: float = 10.0
@export var speed: float = 100.0

var alive: bool = true
var state: State = State.WANDERING

func _process(_delta: float) -> void:
	if state == State.WANDERING:
		_wander()
	if state == State.ATTACKING:
		_attack()

func _take_damage(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		alive = false


func _load_attack() -> void:
	pass


func _attack() -> void:
	pass


func _wander() -> void:
	pass
