extends Node2D

const FADE_DURATION: float = 0.2

var _damage = 0.0
var _attack_position: Vector2

func trigger_hit(damage: float, attack_position: Vector2) -> void:
	_damage = damage
	_attack_position = attack_position
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)

func _on_area_2d_body_entered(body) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(_damage, _attack_position)
