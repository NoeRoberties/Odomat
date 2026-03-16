## Singleton (AutoLoad) qui gère les modules équipés du robot et son inventaire.
##
## Accès depuis n'importe quel script :
##   RobotModules.equip(module)
##   RobotModules.get_speed_bonus()
##   var slot_content : ModuleData = RobotModules.equipped["right_arm"]
extends Node


## Émis quand un module est équipé. Paramètres : clé du slot, ModuleData.
signal module_equipped(slot: String, module: ModuleData)

## Émis quand un module est retiré. Paramètre : clé du slot.
signal module_unequipped(slot: String)

## Liste ordonnée des clés d'emplacements (utilisée par l'UI pour itérer).
const SLOTS: Array[String] = ["right_arm", "left_arm", "legs", "brain_chip"]

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

	# Fallback utile en dev si aucun fichier .tres n'est encore créé.
	if inventory.is_empty():
		push_warning("No module resources found in %s, using hardcoded test inventory." % MODULES_DIR)
		_populate_test_inventory()

	_equip_default_modules()


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


## Retourne le bonus de vitesse total de tous les modules équipés.
func get_speed_bonus() -> float:
	var total := 0.0
	for m: ModuleData in equipped.values():
		if m != null:
			total += m.speed_bonus
	return total


## Retourne le bonus de dégâts total.
func get_damage_bonus() -> int:
	var total := 0
	for m: ModuleData in equipped.values():
		if m != null:
			total += m.damage_bonus
	return total


## Retourne le bonus de portée d'attaque total.
func get_range_bonus() -> float:
	var total := 0.0
	for m: ModuleData in equipped.values():
		if m != null:
			total += m.range_bonus
	return total


## Retourne le multiplicateur de cooldown combiné (produit de tous les modules).
func get_cooldown_multiplier() -> float:
	var mult := 1.0
	for m: ModuleData in equipped.values():
		if m != null:
			mult *= m.cooldown_multiplier
	return mult


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


func _equip_default_modules() -> void:
	for slot_key_name: String in SLOTS:
		equipped[slot_key_name] = null

	var first_per_slot: Dictionary = {}
	for module: ModuleData in inventory:
		var slot := slot_key(module.slot)
		if slot != "" and not first_per_slot.has(slot):
			first_per_slot[slot] = module

	for slot_key_name: String in SLOTS:
		if first_per_slot.has(slot_key_name):
			equip(first_per_slot[slot_key_name])

func _populate_test_inventory() -> void:
	# ── Bras droit ──
	var arm_r_std := _make_module("Standard Arm", ModuleData.Slot.RIGHT_ARM,
		"A standard robotic arm. Nothing special.")

	var arm_r_heavy := _make_module("Heavy Arm", ModuleData.Slot.RIGHT_ARM,
		"Hits harder, but servomotors are slower.")
	arm_r_heavy.damage_bonus = 2
	arm_r_heavy.cooldown_multiplier = 1.3

	var arm_r_rapid := _make_module("Rapid Arm", ModuleData.Slot.RIGHT_ARM,
		"Ultra-fast servomotors. Less force, higher attack speed.")
	arm_r_rapid.damage_bonus = -1
	arm_r_rapid.cooldown_multiplier = 0.65

	# ── Bras gauche ──
	var arm_l_std := _make_module("Standard Arm", ModuleData.Slot.LEFT_ARM,
		"A standard robotic arm.")

	var arm_l_shield := _make_module("Shield Arm", ModuleData.Slot.LEFT_ARM,
		"Integrates a passive deflector. Slightly reduces combat range.")
	arm_l_shield.range_bonus = -10.0

	var arm_l_reach := _make_module("Extended Arm", ModuleData.Slot.LEFT_ARM,
		"Telescopic arm. Improves attack range.")
	arm_l_reach.range_bonus = 30.0

	# ── Jambes ──
	var legs_std := _make_module("Standard Legs", ModuleData.Slot.LEGS,
		"Reliable base locomotion.")

	var legs_sprint := _make_module("Sprint Legs", ModuleData.Slot.LEGS,
		"Boosted actuators. Significantly faster movement.")
	legs_sprint.speed_bonus = 70.0

	var legs_combat := _make_module("Combat Legs", ModuleData.Slot.LEGS,
		"Stabilizing gyroscopes. Improves precision and range.")
	legs_combat.range_bonus = 25.0
	legs_combat.speed_bonus = -20.0

	# ── Puce cérébrale ──
	var chip_std := _make_module("Standard Chip", ModuleData.Slot.BRAIN_CHIP,
		"Baseline processor.")

	var chip_tactical := _make_module("Tactical Chip", ModuleData.Slot.BRAIN_CHIP,
		"Optimized combat algorithms. Reduces reaction time and improves range.")
	chip_tactical.cooldown_multiplier = 0.80
	chip_tactical.range_bonus = 15.0

	var chip_overclock := _make_module("Overclock Chip", ModuleData.Slot.BRAIN_CHIP,
		"Overclocked processor. Speed and damage boost, but unstable long-term.")
	chip_overclock.speed_bonus = 30.0
	chip_overclock.damage_bonus = 1
	chip_overclock.cooldown_multiplier = 0.9

	inventory = [
		arm_r_std,  arm_r_heavy,   arm_r_rapid,
		arm_l_std,  arm_l_shield,  arm_l_reach,
		legs_std,   legs_sprint,   legs_combat,
		chip_std,   chip_tactical, chip_overclock,
	]


func _make_module(
		p_name: String,
		p_slot: ModuleData.Slot,
		p_desc: String) -> ModuleData:
	var m := ModuleData.new()
	m.module_name = p_name
	m.slot = p_slot
	m.description = p_desc
	return m
