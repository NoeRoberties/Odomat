extends Area2D
class_name Arrow

var speed: float = 200.0
var hit_size: float = 60.0
var direction: Vector2 = Vector2.ZERO
var arrow_type: String = ""

func _ready() -> void:
	if $CollisionShape2D.shape == null:
		$CollisionShape2D.shape = RectangleShape2D.new()
	($CollisionShape2D.shape as RectangleShape2D).size = Vector2(hit_size, hit_size)

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta
	var vp = get_viewport_rect().size
	if position.x < -400 or position.x > vp.x + 400 or position.y < -400 or position.y > vp.y + 400:
		queue_free()
