class_name MenuHeader
extends VBoxContainer

signal close_pressed

@export var title_text: String = "Title"
@export var close_button_text: String = " ✕ "

@onready var _title_label: Label = $HeaderBar/TitleLabel
@onready var _close_button: Button = $HeaderBar/CloseButton


func _ready() -> void:
	_apply_visuals()
	_close_button.pressed.connect(func(): close_pressed.emit())


func set_title(new_title: String) -> void:
	title_text = new_title
	if is_instance_valid(_title_label):
		_title_label.text = title_text


func _apply_visuals() -> void:
	_title_label.text = title_text
	_close_button.text = close_button_text
