extends Node2D

@export var base_color: Color = Color(0.42, 0.68, 0.42):
	set(value):
		base_color = value
		if is_inside_tree():
			_update_colors()


func _ready() -> void:
	_update_colors()


func _update_colors() -> void:
	$Top.color   = base_color
	$Left.color  = base_color.darkened(0.30)
	$Right.color = base_color.darkened(0.45)
