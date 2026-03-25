extends CanvasLayer

var _is_open := false

# ── @onready ──────────────────────────────────────────────────────────────────
@onready var _overlay : ColorRect       = $Overlay
@onready var _center  : CenterContainer = $Center
@onready var _popup   : CenterContainer = %ModuleSelectionPopup
@onready var _menu_header : MenuHeader  = %MenuHeader
@onready var _top_row : EquipmentRow    = %TopRow
@onready var _middle_row : EquipmentRow = %MiddleRow
@onready var _bottom_row : EquipmentRow = %BottomRow

## slot_key → EquipmentSlot
var _slot_controls : Dictionary = {}


func _ready() -> void:
	_slot_controls.clear()

	# Récupère tous les slots depuis les rows paramétrables.
	for row: EquipmentRow in [_top_row, _middle_row, _bottom_row]:
		row.slot_pressed.connect(_open_slot_popup)
		var row_slots: Dictionary = row.get_slot_controls()
		for slot_key: String in row_slots:
			_slot_controls[slot_key] = row_slots[slot_key]

	# Fermeture du diagramme principal
	_menu_header.close_pressed.connect(_close)
	# Fermeture du popup (signal émis par module_selection_popup.gd)
	_popup.popup_closed.connect(_close_popup)

	# Signaux du singleton
	RobotModules.module_equipped.connect(_on_module_equipped)
	RobotModules.module_unequipped.connect(_on_module_unequipped)

	# Synchronise les labels du diagramme avec les modules déjà équipés au démarrage
	_update_body_labels()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.is_action_pressed("open_inventory"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif _is_open and event.is_action_pressed("escape_inventory"):
		if _popup.visible:
			_close_popup()   # Retour au diagramme corporel
		else:
			_close()         # Ferme tout
		get_viewport().set_input_as_handled()


# ── Visibilité principale ─────────────────────────────────────────────────────

func _toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()


func _open() -> void:
	get_tree().paused = true
	_is_open          = true
	_overlay.visible  = true
	_center.visible   = true
	_popup.visible    = false


func _close() -> void:
	get_tree().paused = false
	_is_open          = false
	_overlay.visible  = false
	_center.visible   = false
	_popup.visible    = false


# ── Popup de slot ─────────────────────────────────────────────────────────────

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
		var module: ModuleData = RobotModules.get_equipped_module_data(slot_key)
		var slot_control: EquipmentSlot = _slot_controls[slot_key]
		if module != null:
			slot_control.set_equipped_name(module.module_name)
		else:
			slot_control.set_empty()


# ── Réaction aux signaux de RobotModules ──────────────────────────────────────

func _on_module_equipped(slot: String, module: ModuleData) -> void:
	if _slot_controls.has(slot):
		(_slot_controls[slot] as EquipmentSlot).set_equipped_name(module.module_name)
	# Délègue le rafraîchissement au popup s'il est visible
	if _popup.visible:
		_popup.refresh_for_slot(slot)


func _on_module_unequipped(slot: String) -> void:
	if _slot_controls.has(slot):
		(_slot_controls[slot] as EquipmentSlot).set_empty()
	if _popup.visible:
		_popup.refresh_for_slot(slot)
