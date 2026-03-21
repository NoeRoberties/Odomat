extends CharacterBody2D

var pos : Vector2
var rota : float
var dir : float
var speed = 1000
var lifetime = 3.0
var can_collide = false
var target : Node = null

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	velocity = Vector2(speed, 0).rotated(dir)
	await get_tree().create_timer(0.1).timeout
	can_collide = true

func _physics_process(delta: float) -> void:
	move_and_slide()

	if can_collide and get_slide_collision_count() > 0:
		queue_free()

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
