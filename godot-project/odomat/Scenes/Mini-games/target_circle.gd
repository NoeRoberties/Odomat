extends Area2D

@export var circle_radius: float = 30.0
@export var circle_color: Color = Color.WHITE
@export var line_width: float = 4.0

func _ready() -> void:
	var shape = CircleShape2D.new()
	shape.radius = circle_radius
	$CollisionShape2D.shape = shape

func _draw() -> void:
	draw_circle(Vector2.ZERO, circle_radius, circle_color, false, line_width, true)
