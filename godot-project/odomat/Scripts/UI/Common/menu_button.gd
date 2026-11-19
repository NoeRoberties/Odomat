class_name DefaultMenuButton
extends TextureButton

signal menu_pressed

@export var button_text := "Button"
@export var font_size := 22
@export var button_sprite: Texture2D

@onready var _sprite: TextureRect = %MenuButtonSprite
@onready var _label: Label = %MenuButtonLabel

var _hover_tween: Tween


func _ready() -> void:
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_sprite.texture = button_sprite
	_label.text = button_text
	_label.add_theme_font_size_override("font_size", font_size)
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_update_pivot)
	_update_pivot()


func _on_pressed() -> void:
	scale = Vector2.ONE
	menu_pressed.emit()


func _on_mouse_entered() -> void:
	_tween_scale(1.04)


func _on_mouse_exited() -> void:
	_tween_scale(1.0)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _tween_scale(target_scale: float) -> void:
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", Vector2.ONE * target_scale, 0.12)
