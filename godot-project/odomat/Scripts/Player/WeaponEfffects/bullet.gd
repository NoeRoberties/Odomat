extends Area2D

const BASE_RADIUS: float = 8.0
const BASE_DAMAGE: float = 1.0
const BASE_KNOCKBACK: float = 150.0
const LIFETIME: float = 3.0

var _dir := Vector2.RIGHT
var _speed := 600.0
var _size := 1.0
var _life := LIFETIME
var _animation: String = "default"


func setup(dir: Vector2, speed: float, size: float, animation: String) -> void:
	_dir = dir
	_speed = speed
	_size = size
	_animation = animation


func _ready() -> void:
	scale = Vector2.ONE * _size
	rotation = _dir.angle()
	if _animation == "default":
		$FullyChargedHitbox.disabled = true
	if _animation == "fully_charged":
		$DefaultHitbox.disabled = true
	$AnimatedSprite2D.play(_animation)


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
		queue_free()
