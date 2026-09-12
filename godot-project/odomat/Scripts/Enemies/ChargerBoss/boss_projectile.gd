extends Area2D
class_name BossProjectile

const SPEED: float = 210.0
const DAMAGE: int = 12
const KNOCKBACK_FORCE: float = 200.0
const LIFETIME: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var _lifetime_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return

	global_position += direction * SPEED * delta
	_lifetime_timer += delta

	if _lifetime_timer >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE, global_position, KNOCKBACK_FORCE)
		queue_free()
	elif not body.is_in_group("enemies") and not body is Area2D:
		# Collided with wall or obstacle
		queue_free()
