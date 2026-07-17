extends CanvasLayer

# ── @onready ──────────────────────────────────────────────────────────────────
@onready var _overlay : ColorRect       = $Overlay
@onready var _center  : CenterContainer = $Center
@onready var _popup   : CenterContainer = %ModuleSelectionPopup
@onready var _menu_header : MenuHeader  = %MenuHeader
@onready var _body_diagram : Control    = %BodyDiagram

## slot_key → EquipmentSlot
var _slot_controls : Dictionary = {}


func _ready() -> void:
	GameState.current_state = GameState.GameState.MENU
	_overlay.visible  = true
	_center.visible   = true
	_popup.visible    = false
	_slot_controls.clear()

	# Récupère tous les slots directement depuis le BodyDiagram.
	for child in _body_diagram.get_children():
		if child is EquipmentSlot:
			if child.slot_key != "":
				_slot_controls[child.slot_key] = child
			child.slot_pressed.connect(_open_slot_popup)

	# Fermeture du diagramme principal
	_menu_header.close_pressed.connect(_close)
	# Fermeture du popup (signal émis par module_selection_popup.gd)
	_popup.popup_closed.connect(_close_popup)

	# Signaux du singleton
	ModulesInventory.module_equipped.connect(_on_module_equipped)
	ModulesInventory.module_unequipped.connect(_on_module_unequipped)

	# Synchronise les labels du diagramme avec les modules déjà équipés au démarrage
	_update_body_labels()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape_inventory") or event.is_action_pressed("open_inventory"):
		if _popup.visible:
			_close_popup()
		else:
			_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameState.current_state = GameState.GameState.PLAYING
	queue_free()

func _open_slot_popup(slot_key: String) -> void:
	_center.visible = false
	_popup.visible  = true
	_popup.open_for_slot(slot_key)


func _close_popup() -> void:
	_popup.visible  = false
	_center.visible = true


# ── Labels du diagramme corporel ──────────────────────────────────────────────

func _update_body_labels() -> void:
	for slot_key: String in _slot_controls:
		var module: ModuleData = ModulesInventory.get_equipped_module_data(slot_key)
		var slot_control: EquipmentSlot = _slot_controls[slot_key]
		if module != null:
			slot_control.set_equipped(module)
		else:
			slot_control.set_empty()


# ── Réaction aux signaux de ModulesInventory ──────────────────────────────────────

func _on_module_equipped(slot: String, module: ModuleData) -> void:
	if _slot_controls.has(slot):
		(_slot_controls[slot] as EquipmentSlot).set_equipped(module)
	# Délègue le rafraîchissement au popup s'il est visible
	if _popup.visible:
		_popup.refresh_for_slot(slot)


func _on_module_unequipped(slot: String) -> void:
	if _slot_controls.has(slot):
		(_slot_controls[slot] as EquipmentSlot).set_empty()
	if _popup.visible:
		_popup.refresh_for_slot(slot)
