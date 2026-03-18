## Singleton (AutoLoad) qui gère les modules équipés du robot et son inventaire.
##
## Accès depuis n'importe quel script :
##   RobotModules.equip(module)
##   var slot_content : ModuleData = RobotModules.equipped["right_arm"]
extends Node


## Émis quand un module est équipé. Paramètres : clé du slot, ModuleData.
signal module_equipped(slot: String, module: ModuleData)

## Émis quand un module est retiré. Paramètre : clé du slot.
signal module_unequipped(slot: String)

## Dossier de configuration des modules (.tres).
const MODULES_DIR := "res://Resources/Modules"

## Modules actuellement équipés. Valeur null = emplacement vide.
var equipped: Dictionary = {
	"right_arm":  null,
	"left_arm":   null,
	"legs":       null,
	"brain_chip": null,
}

## Tous les modules que le joueur possède (son "sac").
var inventory: Array[ModuleData] = []


func _ready() -> void:
	_load_modules_from_resources()


# ── API publique ──────────────────────────────────────────────────────────────

## Équipe un module sur son emplacement. Remplace le module déjà présent.
func equip(module: ModuleData) -> void:
	var slot := slot_key(module.slot)
	equipped[slot] = module
	module_equipped.emit(slot, module)


## Retire le module de l'emplacement donné (clé string).
func unequip(slot: String) -> void:
	equipped[slot] = null
	module_unequipped.emit(slot)


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

func _load_modules_from_resources() -> void:
	inventory.clear()

	var dir := DirAccess.open(MODULES_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tres"):
			continue

		var res_path := "%s/%s" % [MODULES_DIR, file_name]
		var module_res := load(res_path)
		if module_res is ModuleData:
			inventory.append(module_res)
		else:
			push_warning("Ignored non-ModuleData resource: %s" % res_path)
	dir.list_dir_end()

	inventory.sort_custom(func(a: ModuleData, b: ModuleData) -> bool:
		return a.module_name.nocasecmp_to(b.module_name) < 0
	)


func _make_module(
		p_name: String,
		p_slot: ModuleData.Slot,
		p_desc: String) -> ModuleData:
	var m := ModuleData.new()
	m.module_name = p_name
	m.slot = p_slot
	m.description = p_desc
	return m
