extends Node2D

const FADE_DURATION: float = 0.2
const STRONG_FADE_DURATION: float = 0.35
const STRONG_POP_SCALE: float = 1.25
const STEP_ROTATION_OFFSET: Array[float] = [0.0, -PI / 2.0, -PI / 2.0, -PI / 2.0]
const STEP_MIRRORED: Array[bool] = [false, false, true, false]

var _damage = 0.0
var _attack_position: Vector2
var _knockback_force: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shapes: Array[CollisionShape2D] = [
	$Area2D/Hit1Shape,
	$Area2D/Hit2Shape,
	$Area2D/Hit3Shape,
	$Area2D/Hit4Shape,
]


func trigger_hit(damage: float, attack_position: Vector2, knockback_force: float, combo_step: int = 0, is_strong: bool = false) -> void:
	_damage = damage
	_attack_position = attack_position
	_knockback_force = knockback_force

	var step := clampi(combo_step, 0, _shapes.size() - 1)
	rotation += STEP_ROTATION_OFFSET[step]
	if STEP_MIRRORED[step]:
		scale.x = -scale.x
	_sprite.play("hit_%d" % (step + 1))
	for i in _shapes.size():
		_shapes[i].disabled = i != step

	var tween = create_tween()
	if is_strong:
		var base_scale := scale
		scale = base_scale * 0.8
		tween.tween_property(self, "scale", base_scale * STRONG_POP_SCALE, 0.08)
		tween.tween_property(self, "modulate:a", 0.0, STRONG_FADE_DURATION)
	else:
		tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)


func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(_damage, _attack_position, _knockback_force)
