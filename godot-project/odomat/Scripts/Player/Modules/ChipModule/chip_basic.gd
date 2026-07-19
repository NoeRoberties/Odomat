class_name ChipIdleModule
extends Module

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_sprite.animation = "walk_left"
	_original_color = _sprite.self_modulate
