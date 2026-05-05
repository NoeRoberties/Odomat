class_name LeftArmSwooshModule
extends Module

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_sprite.animation = "walk_left"
