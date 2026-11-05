extends Area2D

const BASE_RADIUS: float = 8.0
const BASE_DAMAGE: float = 1.0
const BASE_KNOCKBACK: float = 150.0
const LIFETIME: float = 3.0

var _dir := Vector2.RIGHT
var _speed := 600.0
var _size := 1.0
var _life := LIFETIME


func setup(dir: Vector2, speed: float, size: float) -> void:
	_dir = dir
	_speed = speed
	_size = size


func _ready() -> void:
	z_index = 100

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BASE_RADIUS * _size
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)
	queue_redraw()



func _draw() -> void:
	draw_circle(Vector2.ZERO, BASE_RADIUS * _size, Color(1.0, 0.6, 0.1))


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(BASE_DAMAGE * _size, global_position - _dir * 10.0, BASE_KNOCKBACK * _size)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()  # mur ou obstacle
