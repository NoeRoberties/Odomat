extends CharacterBody2D

var pos : Vector2
var rota : float
var dir : float
var target : Node = null

var _speed = 1000
var _lifetime = 3.0
var _can_collide = false

const DAMAGE: int = 10
const KNOCKBACK_FORCE: float = 240.0

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	velocity = Vector2(_speed, 0).rotated(dir)
	await get_tree().create_timer(0.1).timeout
	_can_collide = true

func _physics_process(delta: float) -> void:
	move_and_slide()

	if _can_collide and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider is Node and (collider as Node).is_in_group("player") and collider.has_method("take_damage"):
				var knockback := Vector2(_speed, 0).rotated(dir).normalized() * KNOCKBACK_FORCE
				collider.take_damage(DAMAGE, knockback)
		queue_free()

	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
