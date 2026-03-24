class_name Weapon
extends RefCounted


var attack_range: float = 100.0
var attack_damage: int = 1
var attack_cooldown: float = 0.4


func configure_from_module(
		module: ModuleData,
		base_range: float,
		base_damage: int,
		base_cooldown: float) -> void:
	attack_range = base_range
	attack_damage = base_damage
	attack_cooldown = base_cooldown

	if module == null:
		return

	attack_range += module.range_bonus
	attack_damage += module.damage_bonus
	attack_cooldown *= module.cooldown_multiplier


func get_attack_cooldown() -> float:
	return maxf(attack_cooldown, 0.01)


func attack(attacker: Node2D, enemy_group: StringName = &"enemies") -> Node2D:
	push_error("Weapon.attack() must be implemented by subclasses.")
	return null
