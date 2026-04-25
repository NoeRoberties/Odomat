class_name Module
extends Node


@export var module_data: ModuleData
var _sprite: AnimatedSprite2D


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
