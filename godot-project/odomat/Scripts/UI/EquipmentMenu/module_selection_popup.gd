## Popup de sélection de module pour un emplacement donné.
## Utilisé par EquipmentMenu : appelez open_for_slot() pour ouvrir.
extends Control

## Émis quand l'utilisateur clique ✕ pour fermer le popup.
signal popup_closed

const ElementScene: PackedScene = preload("res://Scenes/UI/EquipmentMenu/ModuleListElement.tscn")

const SLOT_LABELS: Dictionary = {
	"right_arm":  "Right Arm",
	"left_arm":   "Left Arm",
	"legs":       "Legs",
	"brain_chip": "Brain Chip",
}

var _selected_slot   : String     = ""
var _selected_module_scene : PackedScene = null
var _selected_module_data : ModuleData = null

@onready var _popup_bg         : TextureRect     = $PopupBackground
@onready var _title_label      : Label           = %TitleLabel

@onready var _module_list_vbox : VBoxContainer   = %ModuleListVBox
@onready var _equip_btn        : TextureButton   = %EquipButton
@onready var _unequip_btn      : TextureButton   = %UnequipButton


func _ready() -> void:
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

	if focused is BaseButton and focused.has_meta("module_scene"):
		var module_scene: PackedScene = focused.get_meta("module_scene")
		focused.button_pressed = not focused.button_pressed  # reflète le clic visuellement
		_on_module_selected(module_scene)
		return true

	return false


## Point d'entrée unique depuis EquipmentMenu — positionne le popup à côté du slot cliqué.
func open_for_slot(slot_key: String, slot_global_pos: Vector2, slot_size: Vector2) -> void:
	_selected_slot    = slot_key
	_selected_module_scene = null
	_selected_module_data = null
	_title_label.text = "Available " + SLOT_LABELS.get(slot_key, slot_key)
	_refresh_list()
	_refresh_detail()
	_position_popup(slot_global_pos, slot_size)


## Positionne dynamiquement le popup à gauche ou à droite du bouton de slot,
## tout en alignant leurs bords supérieurs (coins supérieurs gauche/droite opposés).
func _position_popup(slot_global_pos: Vector2, slot_size: Vector2) -> void:
	var popup_width := _popup_bg.custom_minimum_size.x
	var popup_height := _popup_bg.custom_minimum_size.y
	var screen_size := get_viewport_rect().size
	
	var slot_center := slot_global_pos + slot_size / 2.0
	var margin := 8.0
	
	var target_x: float
	var target_y := slot_global_pos.y
	
	if slot_center.x < screen_size.x / 2.0:
		# Clic sur un bouton à gauche -> Le coin sup-gauche du popup s'aligne sur le coin sup-droit du bouton
		target_x = slot_global_pos.x + slot_size.x + margin
	else:
		# Clic sur un bouton à droite -> Le coin sup-droit du popup s'aligne sur le coin sup-gauche du bouton
		target_x = slot_global_pos.x - popup_width - margin
	
	# S'assure que le popup ne dépasse pas les bords de l'écran
	target_x = clampf(target_x, margin, screen_size.x - popup_width - margin)
	target_y = clampf(target_y, margin, screen_size.y - popup_height - margin)
	
	_popup_bg.global_position = Vector2(target_x, target_y)


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

		var element := ElementScene.instantiate() as ModuleListElement
		var is_equipped := (module_scene == equipped_scene)
		element.set_meta("module_scene", module_scene)
		_module_list_vbox.add_child(element)

		element.set_module(module_data, is_equipped)
		element.button_pressed = (module_scene == _selected_module_scene)
		element.pressed.connect(_on_module_selected.bind(module_scene))

	_wire_list_navigation()
	_restore_focus(equipped_scene)


func _wire_list_navigation() -> void:
	var buttons: Array = _module_list_vbox.get_children()

	for i in range(buttons.size()):
		var btn: BaseButton = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = btn.get_path_to(buttons[i - 1])
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = btn.get_path_to(buttons[i + 1])
		elif is_instance_valid(_equip_btn):
			btn.focus_neighbor_bottom = btn.get_path_to(_equip_btn)

	if not buttons.is_empty():
		var last_btn: BaseButton = buttons[buttons.size() - 1]
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
		var btn: BaseButton = child
		if btn.get_meta("module_scene", null) == scene_to_focus:
			btn.grab_focus()
			return

	(_module_list_vbox.get_child(0) as Control).grab_focus()


func _on_module_selected(module_scene: PackedScene) -> void:
	_selected_module_scene = module_scene
	_selected_module_data = ModulesInventory.get_module_data(module_scene)
	call_deferred("_refresh_list")  # Différé : évite free() sur un nœud verrouillé
	_refresh_detail()


# ── Détails / Boutons d'action ─────────────────────────────────────────────────

func _refresh_detail() -> void:
	if _selected_module_data == null:
		_equip_btn.disabled   = true
		_unequip_btn.disabled = true
		_equip_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		_unequip_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		return

	var is_equipped: bool = ModulesInventory.equipped[_selected_slot] == _selected_module_scene

	_equip_btn.disabled   = is_equipped
	_unequip_btn.disabled = not is_equipped

	_equip_btn.modulate = Color(0.5, 0.5, 0.5, 1.0) if is_equipped else Color(1.0, 1.0, 1.0, 1.0)
	_unequip_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_equipped else Color(0.5, 0.5, 0.5, 1.0)


# ── Boutons Équiper / Retirer ──────────────────────────────────────────────────

func _on_equip_pressed() -> void:
	if _selected_module_scene != null:
		ModulesInventory.equip(_selected_module_scene)
		_refresh_list()
		_refresh_detail()


func _on_unequip_pressed() -> void:
	ModulesInventory.unequip(_selected_slot)
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
