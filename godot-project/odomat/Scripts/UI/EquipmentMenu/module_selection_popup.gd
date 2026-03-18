## Popup de sélection de module pour un emplacement donné.
## Utilisé par EquipmentMenu : appelez open_for_slot() pour ouvrir.
extends CenterContainer

## Émis quand l'utilisateur clique ✕ pour fermer le popup.
signal popup_closed

const SLOT_LABELS: Dictionary = {
	"right_arm":  "🦾 Right Arm",
	"left_arm":   "🦾 Left Arm",
	"legs":       "🦿 Legs",
	"brain_chip": "🧠 Brain Chip",
}

var _selected_slot   : String     = ""
var _selected_module : ModuleData = null

@onready var _menu_header      : MenuHeader      = %MenuHeader
@onready var _module_list_vbox : VBoxContainer   = %ModuleListVBox
@onready var _detail_name      : Label           = %DetailName
@onready var _detail_desc      : Label           = %DetailDesc
@onready var _detail_stats     : Label           = %DetailStats
@onready var _equip_btn        : Button          = %EquipButton
@onready var _unequip_btn      : Button          = %UnequipButton


func _ready() -> void:
	_menu_header.close_pressed.connect(func(): popup_closed.emit())
	_equip_btn.pressed.connect(_on_equip_pressed)
	_unequip_btn.pressed.connect(_on_unequip_pressed)


## Point d'entrée unique depuis EquipmentMenu — positionne le popup sur ce slot.
func open_for_slot(slot_key: String) -> void:
	_selected_slot    = slot_key
	_selected_module  = null
	_menu_header.set_title(SLOT_LABELS.get(slot_key, slot_key))
	_refresh_list()
	_refresh_detail()


## Rafraîchit le contenu seulement si le popup affiche déjà ce slot.
func refresh_for_slot(slot_key: String) -> void:
	if _selected_slot == slot_key:
		_refresh_list()
		_refresh_detail()


# ── Liste de modules ───────────────────────────────────────────────────────────

func _refresh_list() -> void:
	for child in _module_list_vbox.get_children():
		child.free()

	var target_slot  : int        = _slot_key_to_enum(_selected_slot)
	var equipped_mod : ModuleData = RobotModules.equipped[_selected_slot]

	for module: ModuleData in RobotModules.inventory:
		if module.slot != target_slot:
			continue

		var btn := Button.new()
		var prefix := "✓ " if module == equipped_mod else "   "
		btn.text = prefix + module.module_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode    = true
		btn.button_pressed = (module == _selected_module)
		btn.pressed.connect(_on_module_selected.bind(module))
		_module_list_vbox.add_child(btn)


func _on_module_selected(module: ModuleData) -> void:
	_selected_module = module
	call_deferred("_refresh_list")  # Différé : évite free() sur un nœud verrouillé
	_refresh_detail()


# ── Détails ────────────────────────────────────────────────────────────────────

func _refresh_detail() -> void:
	if _selected_module == null:
		_detail_name.text     = "—"
		_detail_desc.text     = ""
		_detail_stats.text    = ""
		_equip_btn.disabled   = true
		_unequip_btn.disabled = true
		return

	var is_equipped: bool = RobotModules.equipped[_selected_slot] == _selected_module

	_detail_name.text     = _selected_module.module_name
	_detail_desc.text     = _selected_module.description
	_detail_stats.text    = _format_stats(_selected_module)
	_equip_btn.disabled   = is_equipped
	_unequip_btn.disabled = not is_equipped


func _format_stats(m: ModuleData) -> String:
	var parts : PackedStringArray = []
	if m.speed_bonus != 0.0:
		parts.append("Speed        %+.0f px/s" % m.speed_bonus)
	if m.damage_bonus != 0:
		parts.append("Damage       %+d" % m.damage_bonus)
	if m.range_bonus != 0.0:
		parts.append("Range        %+.0f px" % m.range_bonus)
	if m.cooldown_multiplier != 1.0:
		var pct := (m.cooldown_multiplier - 1.0) * 100.0
		parts.append("Cooldown     %+.0f%%" % pct)
	return "\n".join(parts) if not parts.is_empty() else "(no bonus)"


# ── Boutons Équiper / Retirer ──────────────────────────────────────────────────

func _on_equip_pressed() -> void:
	if _selected_module != null:
		RobotModules.equip(_selected_module)


func _on_unequip_pressed() -> void:
	RobotModules.unequip(_selected_slot)
	_selected_module = null


# ── Utilitaires ───────────────────────────────────────────────────────────────

func _slot_key_to_enum(key: String) -> int:
	match key:
		"right_arm":  return ModuleData.Slot.RIGHT_ARM
		"left_arm":   return ModuleData.Slot.LEFT_ARM
		"legs":       return ModuleData.Slot.LEGS
		"brain_chip": return ModuleData.Slot.BRAIN_CHIP
	return ModuleData.Slot.RIGHT_ARM
