extends CharacterBody2D
class_name Enemy

enum {ATTACKING, WANDERING}

@export var health: float = 10.0
@export var speed: float = 100.0

var alive: bool = true


func take_damage(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		alive = false


func attack_player(delta: float) -> void:
	pass


func wander(delta: float) -> void:
	pass
