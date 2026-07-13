class_name Module
extends Node


@export var module_data: ModuleData
var _sprite: AnimatedSprite2D
var _original_color: Color
var _blink_tween: Tween

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_original_color = _sprite.self_modulate

func on_equip(_player: Player) -> void:
	pass


func on_unequip(_player: Player) -> void:
	pass


func handle_input(_player: Player, _event: InputEvent) -> void:
	pass


func handle_physics(_player: Player, _delta: float) -> void:
	pass


func handle_process(_player: Player, _delta: float) -> void:
	pass


func _animate_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()

	_sprite.self_modulate = _original_color
	
	_blink_tween = create_tween()
	_blink_tween.set_parallel(false)  # Sequential animations
	
	for i in range(4):
		_blink_tween.tween_property(_sprite, "self_modulate", Color.RED, 0.08)
		_blink_tween.tween_property(_sprite, "self_modulate", _original_color, 0.08)


func update_animation(move_dir: Vector2) -> void:
	if move_dir == Vector2.ZERO:
		_sprite.stop()
		return
	if move_dir.x < 0.0:
		_sprite.play("walk_left")
		return
	if move_dir.x > 0.0:
		_sprite.play("walk_right")
		return
	if move_dir.y > 0.0:
		_sprite.play()
		return
	if move_dir.y < 0.0:
		_sprite.play()
		return
