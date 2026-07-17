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
var _selected_module_scene : PackedScene = null
var _selected_module_data : ModuleData = null

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
	_equip_btn.focus_mode = Control.FOCUS_ALL
	_unequip_btn.focus_mode = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact_npc"):
		if _activate_focused_control():
			get_viewport().set_input_as_handled()


func _activate_focused_control() -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return false

	if focused == _equip_btn:
		if not _equip_btn.disabled:
			_on_equip_pressed()
		return true

	if focused == _unequip_btn:
		if not _unequip_btn.disabled:
			_on_unequip_pressed()
		return true

	if focused is Button and focused.has_meta("module_scene"):
		var module_scene: PackedScene = focused.get_meta("module_scene")
		focused.button_pressed = not focused.button_pressed  # reflète le clic visuellement
		_on_module_selected(module_scene)
		return true

	return false


## Point d'entrée unique depuis EquipmentMenu — positionne le popup sur ce slot.
func open_for_slot(slot_key: String) -> void:
	_selected_slot    = slot_key
	_selected_module_scene = null
	_selected_module_data = null
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
	var equipped_scene : PackedScene = ModulesInventory.equipped[_selected_slot]

	for module_scene: PackedScene in ModulesInventory.inventory:
		var module_data := ModulesInventory.get_module_data(module_scene)
		if module_data == null:
			continue
		if module_data.slot != target_slot:
			continue

		var btn := Button.new()
		var prefix := "✓ " if module_scene == equipped_scene else "   "
		btn.text = prefix + module_data.module_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode    = true
		btn.focus_mode     = Control.FOCUS_ALL
		btn.button_pressed = (module_scene == _selected_module_scene)
		btn.set_meta("module_scene", module_scene)
		btn.pressed.connect(_on_module_selected.bind(module_scene))
		_module_list_vbox.add_child(btn)

	_wire_list_navigation()
	_restore_focus(equipped_scene)


func _wire_list_navigation() -> void:
	var buttons: Array = _module_list_vbox.get_children()

	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = btn.get_path_to(buttons[i - 1])
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = btn.get_path_to(buttons[i + 1])
		elif is_instance_valid(_equip_btn):
			btn.focus_neighbor_bottom = btn.get_path_to(_equip_btn)

	if not buttons.is_empty():
		var last_btn: Button = buttons[buttons.size() - 1]
		if is_instance_valid(_equip_btn):
			_equip_btn.focus_neighbor_top = _equip_btn.get_path_to(last_btn)
		if is_instance_valid(_unequip_btn):
			_unequip_btn.focus_neighbor_top = _unequip_btn.get_path_to(last_btn)

	if is_instance_valid(_equip_btn) and is_instance_valid(_unequip_btn):
		_equip_btn.focus_neighbor_right = _equip_btn.get_path_to(_unequip_btn)
		_unequip_btn.focus_neighbor_left = _unequip_btn.get_path_to(_equip_btn)

func _restore_focus(equipped_scene: PackedScene) -> void:
	if _module_list_vbox.get_child_count() == 0:
		return

	var scene_to_focus: PackedScene = _selected_module_scene if _selected_module_scene != null else equipped_scene
	for child in _module_list_vbox.get_children():
		var btn: Button = child
		if btn.get_meta("module_scene", null) == scene_to_focus:
			btn.grab_focus()
			return

	(_module_list_vbox.get_child(0) as Button).grab_focus()


func _on_module_selected(module_scene: PackedScene) -> void:
	_selected_module_scene = module_scene
	_selected_module_data = ModulesInventory.get_module_data(module_scene)
	call_deferred("_refresh_list")  # Différé : évite free() sur un nœud verrouillé
	_refresh_detail()


# ── Détails ────────────────────────────────────────────────────────────────────

func _refresh_detail() -> void:
	if _selected_module_data == null:
		_detail_name.text     = "—"
		_detail_desc.text     = ""
		_detail_stats.text    = ""
		_equip_btn.disabled   = true
		_unequip_btn.disabled = true
		return

	var is_equipped: bool = ModulesInventory.equipped[_selected_slot] == _selected_module_scene

	_detail_name.text     = _selected_module_data.module_name
	_detail_desc.text     = _selected_module_data.description
	_detail_stats.text    = _format_stats(_selected_module_data)
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
	if _selected_module_scene != null:
		ModulesInventory.equip(_selected_module_scene)
		# Ensure button/checkmark state updates immediately in this popup.
		_refresh_list()
		_refresh_detail()


func _on_unequip_pressed() -> void:
	ModulesInventory.unequip(_selected_slot)
	# Keep current selection so the player can re-equip the same module quickly.
	_refresh_list()
	_refresh_detail()


# ── Utilitaires ───────────────────────────────────────────────────────────────

func _slot_key_to_enum(key: String) -> int:
	match key:
		"right_arm":  return ModuleData.Slot.RIGHT_ARM
		"left_arm":   return ModuleData.Slot.LEFT_ARM
		"legs":       return ModuleData.Slot.LEGS
		"brain_chip": return ModuleData.Slot.BRAIN_CHIP
	return ModuleData.Slot.RIGHT_ARM
