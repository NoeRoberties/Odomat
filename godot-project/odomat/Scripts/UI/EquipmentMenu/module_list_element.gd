class_name ModuleListElement
extends TextureButton

@onready var _icon: TextureRect = $Margin/Content/Icon
@onready var _name_label: Label = $Margin/Content/RightPart/NameLabel
@onready var _stats_label: Label = $Margin/Content/RightPart/StatsLabel
@onready var _check_icon: Label = $Margin/Content/CheckIcon


func set_module(module_data: ModuleData, is_equipped: bool) -> void:
	if module_data.item_texture != null:
		_icon.texture = module_data.item_texture
		_icon.visible = true
	else:
		_icon.visible = false

	_name_label.text = module_data.module_name
	_check_icon.text = "✓" if is_equipped else ""
	_stats_label.text = _format_stats(module_data)


func _format_stats(m: ModuleData) -> String:
	var parts : PackedStringArray = []
	if m.speed_bonus != 0.0:
		parts.append("Speed: %+.0f" % m.speed_bonus)
	if m.damage_bonus != 0:
		parts.append("Dmg: %+d" % m.damage_bonus)
	if m.range_bonus != 0.0:
		parts.append("Rng: %+.0f" % m.range_bonus)
	if m.cooldown_multiplier != 1.0:
		var pct := (m.cooldown_multiplier - 1.0) * 100.0
		parts.append("Cd: %+.0f%%" % pct)
	return " | ".join(parts) if not parts.is_empty() else "No bonuses"
