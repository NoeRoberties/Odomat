extends Area2D
class_name Arrow

@export var speed: float = 400.0
var direction: Vector2 = Vector2.ZERO
var arrow_type: String = ""

func _ready() -> void:
	pass

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction
	
	if direction == Vector2.RIGHT:
		rotation_degrees = 90
	elif direction == Vector2.LEFT:
		rotation_degrees = -90
	elif direction == Vector2.DOWN:
		rotation_degrees = 180
	elif direction == Vector2.UP:
		rotation_degrees = 0

func _process(delta: float) -> void:
	position += direction * speed * delta
