class_name PlayerModule
extends Node


@export var module_data: ModuleData


func on_equip(_player: CharacterBody2D) -> void:
	pass


func on_unequip(_player: CharacterBody2D) -> void:
	pass


func handle_input(_player: CharacterBody2D, _event: InputEvent) -> void:
	pass


func handle_physics(_player: CharacterBody2D, _delta: float) -> void:
	pass


func handle_process(_player: CharacterBody2D, _delta: float) -> void:
	pass
