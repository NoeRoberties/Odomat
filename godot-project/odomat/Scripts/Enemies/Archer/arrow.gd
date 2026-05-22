extends CharacterBody2D

var pos: Vector2
var rota: float
var dir: float
var target: Node = null
var shooter: Node2D = null

var _speed = 1000.0
var _lifetime = 3.0

const DAMAGE: int = 10
const KNOCKBACK_FORCE: float = 240.0


func _ready() -> void:
	global_position = pos
	global_rotation = rota
	velocity = Vector2(_speed, 0).rotated(dir)
	
	if shooter:
		add_collision_exception_with(shooter)


func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			var knockback := velocity.normalized() * KNOCKBACK_FORCE
			collider.take_damage(DAMAGE, knockback)
		queue_free()

	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
