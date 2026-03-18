class_name EquipmentRow
extends HBoxContainer

signal slot_pressed(slot_key: String)

@export var slot_scene: PackedScene = preload("res://Scenes/EquipmentSlot.tscn")
@export var slots: Array[EquipmentSlotConfig] = []
@export var leading_spacers: int = 0
@export var trailing_spacers: int = 0
@export var spacer_between_slots: bool = false
@export var row_separation: int = 0

var _slot_controls: Dictionary = {}


func _ready() -> void:
	_rebuild()


func get_slot_controls() -> Dictionary:
	return _slot_controls


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_slot_controls.clear()

	for i in range(leading_spacers):
		_add_spacer("LeadSpacer%d" % i)

	for i in range(slots.size()):
		var cfg: EquipmentSlotConfig = slots[i]
		var slot_control: EquipmentSlot = slot_scene.instantiate()
		slot_control.name = _slot_node_name(cfg, i)
		slot_control.slot_key = cfg.slot_key
		slot_control.button_text = cfg.button_text
		slot_control.button_min_size = cfg.button_min_size
		slot_control.empty_text = cfg.empty_text
		slot_control.is_interactive = cfg.is_interactive
		slot_control.slot_pressed.connect(func(slot_key: String): slot_pressed.emit(slot_key))
		add_child(slot_control)

		if cfg.slot_key != "":
			_slot_controls[cfg.slot_key] = slot_control

		if spacer_between_slots and i < slots.size() - 1:
			_add_spacer("MiddleSpacer%d" % i)

	for i in range(trailing_spacers):
		_add_spacer("TrailSpacer%d" % i)


func _add_spacer(spacer_name: String) -> void:
	var spacer := Control.new()
	spacer.name = spacer_name
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)


func _slot_node_name(cfg: EquipmentSlotConfig, index: int) -> String:
	if cfg.slot_key == "":
		return "Slot%d" % index
	return "Slot_%s" % cfg.slot_key
