extends Node

const FLOATING_TEXT_SCENE: PackedScene = preload("res://Scenes/UI/HUD/FloatingDamageText.tscn")


func display_number(value: Variant, position: Vector2, custom_color: Color = Color.WHITE, is_player: bool = false, is_critical: bool = false) -> void:
	if FLOATING_TEXT_SCENE == null:
		return

	var text_instance = FLOATING_TEXT_SCENE.instantiate() as FloatingDamageText
	if text_instance == null:
		return

	var main_scene = get_tree().current_scene
	if main_scene == null:
		main_scene = get_tree().root

	main_scene.add_child(text_instance)
	text_instance.global_position = position
	text_instance.setup(value, custom_color, is_player, is_critical)
