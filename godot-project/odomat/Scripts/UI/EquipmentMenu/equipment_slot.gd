class_name EquipmentSlot
extends VBoxContainer

signal slot_pressed(slot_key: String)

@export var slot_key: String = ""
@export var button_text: String = "Slot"
@export var button_min_size: Vector2 = Vector2(150, 60)
@export var empty_text: String = "⬦ empty"
@export var is_interactive: bool = true

@onready var _button: Button = $SlotButton
@onready var _label: Label = $SlotLabel


func _ready() -> void:
	#theme_override_constants/separation = 2
	_apply_visuals()
	if is_interactive and slot_key != "":
		_button.pressed.connect(func(): slot_pressed.emit(slot_key))


func set_equipped_name(module_name: String) -> void:
	_button.text = "✓ " + module_name


func set_empty() -> void:
	_button.text = empty_text


func _apply_visuals() -> void:
	_label.text = button_text
	_button.text = empty_text
	_button.custom_minimum_size = button_min_size
	_button.disabled = not is_interactive
