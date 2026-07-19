extends Area2D

@export var circle_radius: float = 100.0
@export var circle_color: Color = Color.WHITE
@export var line_width: float = 4.0

func _ready() -> void:
	set_radius(circle_radius)

func set_radius(new_radius: float) -> void:
	circle_radius = new_radius
	if $CollisionShape2D.shape == null:
		$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = circle_radius
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, circle_radius, 0, TAU, 64, circle_color, line_width, true)
