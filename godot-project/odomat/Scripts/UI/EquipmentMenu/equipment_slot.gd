class_name EquipmentSlot
extends Control

signal slot_pressed(slot_key: String)

@export var slot_key: String = ""
@export var empty_text: String = "⬦ empty"
@export var is_interactive: bool = true

@onready var _button: Button = $SlotButton
@onready var _icon: TextureRect = $SlotIcon
@onready var _glowing: TextureRect = $SlotGlowing


func _ready() -> void:
	_glowing.visible = false
	_apply_visuals()
	if is_interactive and slot_key != "":
		_button.pressed.connect(func(): slot_pressed.emit(slot_key))
		_button.focus_mode = Control.FOCUS_ALL
	else:
		_button.focus_mode = Control.FOCUS_NONE


func set_equipped(module: ModuleData) -> void:
	if module.item_texture != null:
		_icon.texture = module.item_texture
		_button.text = ""
	else:
		_icon.texture = null
		_button.text = "✓ " + module.module_name
	_button.tooltip_text = module.module_name


func set_empty() -> void:
	_icon.texture = null
	_button.text = empty_text
	_button.tooltip_text = ""


func get_focus_button() -> Button:
	if is_interactive and slot_key != "":
		return _button
	return null


func focus_slot() -> void:
	var btn := get_focus_button()
	if btn != null:
		btn.grab_focus()


func _apply_visuals() -> void:
	_icon.texture = null
	_button.text = empty_text
	_button.tooltip_text = ""
	_button.disabled = not is_interactive


func set_glowing(active: bool) -> void:
	_glowing.visible = active
