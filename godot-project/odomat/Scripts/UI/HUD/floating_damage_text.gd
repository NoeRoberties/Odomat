extends Node2D
class_name FloatingDamageText

@onready var label: Label = $Label


func setup(value: Variant, custom_color: Color = Color.WHITE, is_player: bool = false, is_critical: bool = false) -> void:
	var text_str := ""
	if value is float:
		text_str = "%.1f" % value if value != int(value) else str(int(value))
	else:
		text_str = str(value)

	if label == null:
		label = $Label

	label.text = text_str

	# Determine text display color
	var display_color := custom_color
	if custom_color == Color.WHITE:
		if is_player:
			display_color = Color(1.0, 0.25, 0.25) # Vivid Red for player damage
		elif is_critical:
			display_color = Color(1.0, 0.85, 0.1) # Bright Gold for critical hits
		else:
			display_color = Color(1.0, 0.95, 0.4) # Warm Yellow for standard enemy hits

	label.add_theme_color_override("font_color", display_color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 6)

	if is_critical:
		label.add_theme_font_size_override("font_size", 24)
	else:
		label.add_theme_font_size_override("font_size", 18)

	# Setup random upward drifting trajectory
	var x_drift := randf_range(-18.0, 18.0)
	var target_pos := global_position + Vector2(x_drift, -45.0)

	scale = Vector2(1.5, 1.5)
	modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)

	# Smooth upward drift
	tween.tween_property(self, "global_position", target_pos, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Scale pop animation
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Fade out near end of motion
	var fade_tween := create_tween()
	fade_tween.tween_interval(0.35)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)

	await tween.finished
	queue_free()
