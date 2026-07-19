extends CanvasLayer

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

var _row_slot_lists : Array = []


func _ready() -> void:
	GameState.current_state = GameState.GameState.MENU
	_overlay.visible  = true
	_center.visible   = true
	_popup.visible    = false
	_slot_controls.clear()
	_row_slot_lists.clear()

	# Récupère tous les slots depuis les rows paramétrables.
	for row: EquipmentRow in [_top_row, _middle_row, _bottom_row]:
		row.slot_pressed.connect(_open_slot_popup)
		var row_slots: Dictionary = row.get_slot_controls()
		for slot_key: String in row_slots:
			_slot_controls[slot_key] = row_slots[slot_key]
		_row_slot_lists.append(row.get_ordered_slots())

	# Fermeture du diagramme principal
	_menu_header.close_pressed.connect(_close)
	# Fermeture du popup (signal émis par module_selection_popup.gd)
	_popup.popup_closed.connect(_close_popup)

	# Signaux du singleton
	ModulesInventory.module_equipped.connect(_on_module_equipped)
	ModulesInventory.module_unequipped.connect(_on_module_unequipped)

	# Synchronise les labels du diagramme avec les modules déjà équipés au démarrage
	_update_body_labels()

	await get_tree().process_frame
	_setup_gamepad_navigation()
	_focus_first_slot()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape_inventory") or event.is_action_pressed("open_inventory"):
		if _popup.visible:
			_close_popup()
		else:
			_close()
		get_viewport().set_input_as_handled()
		return

	if not _popup.visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact_npc")):
		if _activate_focused_slot():
			get_viewport().set_input_as_handled()


func _activate_focused_slot() -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null:
		return false
	
	for slot_key: String in _slot_controls:
		var slot: EquipmentSlot = _slot_controls[slot_key]
		if slot.get_focus_button() == focused:
			_open_slot_popup(slot_key)
			return true
	return false

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
	_focus_first_slot()


# ── Labels du diagramme corporel ──────────────────────────────────────────────

func _update_body_labels() -> void:
	for slot_key: String in _slot_controls:
		var module: ModuleData = ModulesInventory.get_equipped_module_data(slot_key)
		var slot_control: EquipmentSlot = _slot_controls[slot_key]
		if module != null:
			slot_control.set_equipped_name(module.module_name)
		else:
			slot_control.set_empty()


# ── Réaction aux signaux de ModulesInventory ──────────────────────────────────────

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


func _setup_gamepad_navigation() -> void:
	var rows_buttons: Array = []
	for row_slots: Array in _row_slot_lists:
		var buttons: Array = []
		for slot: EquipmentSlot in row_slots:
			var btn: Button = slot.get_focus_button()
			if btn != null:
				buttons.append(btn)
		rows_buttons.append(buttons)

	for buttons: Array in rows_buttons:
		for i in range(buttons.size()):
			var btn: Button = buttons[i]
			if i > 0:
				btn.focus_neighbor_left = btn.get_path_to(buttons[i - 1])
			if i < buttons.size() - 1:
				btn.focus_neighbor_right = btn.get_path_to(buttons[i + 1])

	for r in range(rows_buttons.size() - 1):
		var current_row: Array = rows_buttons[r]
		var next_row: Array = rows_buttons[r + 1]
		if current_row.is_empty() or next_row.is_empty():
			continue
		for btn: Button in current_row:
			var target: Button = _closest_button_by_x(btn, next_row)
			btn.focus_neighbor_bottom = btn.get_path_to(target)
			target.focus_neighbor_top = target.get_path_to(btn)


func _closest_button_by_x(reference: Button, candidates: Array) -> Button:
	var best: Button = candidates[0]
	var best_dist: float = INF
	for c: Button in candidates:
		var d: float = abs(c.global_position.x - reference.global_position.x)
		if d < best_dist:
			best_dist = d
			best = c
	return best


func _focus_first_slot() -> void:
	for row_slots: Array in _row_slot_lists:
		for slot: EquipmentSlot in row_slots:
			var btn: Button = slot.get_focus_button()
			if btn != null:
				btn.grab_focus()
				return
