extends CharacterBody2D
class_name Enemy

enum {ATTACKING, WANDERING, LOADING}

@export var health: float = 10.0
@export var speed: float = 100.0

var alive: bool = true
var state = WANDERING

func _process(_delta: float) -> void:
	if state == WANDERING:
		wander()
	if state == ATTACKING:
		attack()

func take_damage(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		alive = false


func load_attack() -> void:
	pass


func attack() -> void:
	pass


func wander() -> void:
	pass
