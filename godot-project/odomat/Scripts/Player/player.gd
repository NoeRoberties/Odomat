extends CharacterBody2D

var _npc_to_interact: NPC = null
var _equipped_modules: Dictionary = {
	"right_arm":  null,
	"left_arm":   null,
	"legs":       null,
	"brain_chip": null,
}

const EquipmentMenuScene: PackedScene = preload("res://Scenes/UI/EquipmentMenu/EquipmentMenu.tscn")
var _equipment_menu: CanvasLayer = null


func _ready() -> void:
	RobotModules.module_equipped.connect(_on_module_equipped)
	RobotModules.module_unequipped.connect(_on_module_unequipped)
	_refresh_all_modules()


func _exit_tree() -> void:
	for slot: String in _equipped_modules:
		var module := _equipped_modules[slot] as PlayerModule
		if module != null:
			module.on_unequip(self)
			module.queue_free()
			_equipped_modules[slot] = null


func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	if event.is_action_pressed("open_inventory"):
		add_child(EquipmentMenuScene.instantiate())
		return

	if event.is_action_pressed("interact_npc") and _npc_to_interact != null:
		_npc_to_interact._launch_dialogue()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is NPC:
		_npc_to_interact = body


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == _npc_to_interact:
		_npc_to_interact = null


func _on_module_equipped(slot: String, _module: ModuleData) -> void:
	_refresh_module_slot(slot)


func _on_module_unequipped(slot: String) -> void:
	_refresh_module_slot(slot)


func _refresh_all_modules() -> void:
	for slot: String in _equipped_modules:
		_refresh_module_slot(slot)


func _refresh_module_slot(slot: String) -> void:
	if not _equipped_modules.has(slot):
		return

	var old_module := _equipped_modules[slot] as PlayerModule
	if old_module != null:
		old_module.on_unequip(self)
		old_module.queue_free()

	var next_module := RobotModules.create_equipped_module_instance(slot)
	_equipped_modules[slot] = next_module

	if next_module != null:
		add_child(next_module)
		next_module.on_equip(self)
