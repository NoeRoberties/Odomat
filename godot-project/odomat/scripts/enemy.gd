extends CharacterBody2D

const MAX_HP: int = 5
const FLASH_DURATION: float = 0.25

var hp: int = MAX_HP

@onready var visual: Node2D = $Visual

var _tween: Tween


func _ready() -> void:
	add_to_group("enemies")


func take_damage(amount: int) -> void:
	# hp -= amount  
	_flash_red()
	if hp <= 0:
		queue_free()


func _flash_red() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
		visual.modulate = Color.WHITE

	_tween = create_tween()
	_tween.tween_property(visual, "modulate", Color.RED,          FLASH_DURATION * 0.15)
	_tween.tween_property(visual, "modulate", Color(1, 0.6, 0.6), FLASH_DURATION * 0.35)
	_tween.tween_property(visual, "modulate", Color.WHITE,        FLASH_DURATION * 0.50)
