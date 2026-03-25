## Singleton (AutoLoad) qui gère les modules équipés du robot et son inventaire.
##
## Accès depuis n'importe quel script :
##   RobotModules.equip(module_scene)
##   var slot_content : PackedScene = RobotModules.equipped["right_arm"]
extends Node


## Émis quand un module est équipé. Paramètres : clé du slot, ModuleData.
signal module_equipped(slot: String, module: ModuleData)

## Émis quand un module est retiré. Paramètre : clé du slot.
signal module_unequipped(slot: String)

## Dossier de configuration des modules (scènes .tscn).
const MODULE_SCENES_DIR := "res://Scenes/Modules"

## Modules (scènes) actuellement équipés. Valeur null = emplacement vide.
var equipped: Dictionary = {
	"right_arm":  null,
	"left_arm":   null,
	"legs":       null,
	"brain_chip": null,
}

## Tous les modules que le joueur possède (son "sac") sous forme de scènes.
var inventory: Array[PackedScene] = []


func _instantiate_module(module_scene: PackedScene) -> PlayerModule:
	if module_scene == null:
		return null

	var instance := module_scene.instantiate()
	if instance is PlayerModule:
		return instance as PlayerModule

	if instance is Node:
		(instance as Node).queue_free()
	push_warning("Ignored scene that does not inherit PlayerModule: %s" % module_scene.resource_path)
	return null


func _ready() -> void:
	_load_modules_from_scenes()


# ── API publique ──────────────────────────────────────────────────────────────

## Équipe un module sur son emplacement. Remplace le module déjà présent.
func equip(module_scene: PackedScene) -> void:
	var data := get_module_data(module_scene)
	if data == null:
		return

	var slot := slot_key(data.slot)
	equipped[slot] = module_scene
	module_equipped.emit(slot, data)


## Retire le module de l'emplacement donné (clé string).
func unequip(slot: String) -> void:
	equipped[slot] = null
	module_unequipped.emit(slot)


func get_module_data(module_scene: PackedScene) -> ModuleData:
	var module_instance := _instantiate_module(module_scene)
	if module_instance == null:
		return null

	var data := module_instance.module_data
	module_instance.queue_free()
	return data


func get_equipped_module_data(slot: String) -> ModuleData:
	return get_module_data(equipped.get(slot, null) as PackedScene)


func create_equipped_module_instance(slot: String) -> PlayerModule:
	return _instantiate_module(equipped.get(slot, null) as PackedScene)


## Convertit un enum ModuleData.Slot en clé string utilisée dans equipped/SLOTS.
func slot_key(slot_enum: ModuleData.Slot) -> String:
	match slot_enum:
		ModuleData.Slot.RIGHT_ARM:  return "right_arm"
		ModuleData.Slot.LEFT_ARM:   return "left_arm"
		ModuleData.Slot.LEGS:       return "legs"
		ModuleData.Slot.BRAIN_CHIP: return "brain_chip"
	return ""


# ── Inventaire de test ────────────────────────────────────────────────────────
## Supprime ou remplace cette fonction quand tu implémentes la sauvegarde.

func _load_modules_from_scenes() -> void:
	inventory.clear()

	var dir := DirAccess.open(MODULE_SCENES_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tscn"):
			continue

		var res_path := "%s/%s" % [MODULE_SCENES_DIR, file_name]
		var module_res := load(res_path)
		if module_res is PackedScene:
			inventory.append(module_res)
		else:
			push_warning("Ignored non-module scene resource: %s" % res_path)
	dir.list_dir_end()

	inventory.sort_custom(func(a: PackedScene, b: PackedScene) -> bool:
		var data_a := get_module_data(a)
		var data_b := get_module_data(b)
		if data_a == null:
			return false
		if data_b == null:
			return true
		return data_a.module_name.nocasecmp_to(data_b.module_name) < 0
	)

	for slot_name: String in equipped.keys():
		equipped[slot_name] = null

	for module_scene: PackedScene in inventory:
		var module_data := get_module_data(module_scene)
		if module_data == null:
			continue
		var slot := slot_key(module_data.slot)
		if equipped[slot] == null:
			equip(module_scene)
