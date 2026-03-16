extends CanvasLayer # AutoLoaded scene

var _is_open := false

# ── @onready ──────────────────────────────────────────────────────────────────
@onready var _overlay : ColorRect       = $Overlay
@onready var _center  : CenterContainer = $Center
@onready var _popup   : CenterContainer = %ModuleSelectionPopup

## slot_key → Label sous chaque partie du corps
var _equipped_labels : Dictionary = {}


func _ready() -> void:
	_equipped_labels = {
		"right_arm":  %LblRightArm,
		"left_arm":   %LblLeftArm,
		"legs":       %LblLegs,
		"brain_chip": %LblBrainChip,
	}

	# Clic sur une partie du corps → ouvre le popup pour ce slot
	%BtnRightArm.pressed.connect(_open_slot_popup.bind("right_arm"))
	%BtnLeftArm.pressed.connect(_open_slot_popup.bind("left_arm"))
	%BtnLegs.pressed.connect(_open_slot_popup.bind("legs"))
	%BtnBrainChip.pressed.connect(_open_slot_popup.bind("brain_chip"))

	# Fermeture du diagramme principal
	%CloseButton.pressed.connect(_close)
	# Fermeture du popup (signal émis par module_selection_popup.gd)
	_popup.popup_closed.connect(_close_popup)

	# Signaux du singleton
	RobotModules.module_equipped.connect(_on_module_equipped)
	RobotModules.module_unequipped.connect(_on_module_unequipped)

	# Synchronise les labels du diagramme avec les modules déjà équipés au démarrage
	_update_body_labels()


func _unhandled_input(event: InputEvent) -> void:
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
	for slot_key: String in _equipped_labels:
		var module : ModuleData = RobotModules.equipped[slot_key]
		_equipped_labels[slot_key].text = "✓ " + module.module_name if module != null else "⬦ empty"


# ── Réaction aux signaux de RobotModules ──────────────────────────────────────

func _on_module_equipped(slot: String, module: ModuleData) -> void:
	if _equipped_labels.has(slot):
		_equipped_labels[slot].text = "✓ " + module.module_name
	# Délègue le rafraîchissement au popup s'il est visible
	if _popup.visible:
		_popup.refresh_for_slot(slot)


func _on_module_unequipped(slot: String) -> void:
	if _equipped_labels.has(slot):
		_equipped_labels[slot].text = "⬦ empty"
	if _popup.visible:
		_popup.refresh_for_slot(slot)
