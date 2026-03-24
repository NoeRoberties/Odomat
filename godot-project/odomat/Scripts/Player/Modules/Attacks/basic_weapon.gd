class_name BasicWeapon
extends Weapon


func attack(attacker: Node2D, enemy_group: StringName = &"enemies") -> Node2D:
	if attacker == null:
		return null

	var nearest_enemy: Node2D = null
	var nearest_dist: float = attack_range

	for enemy in attacker.get_tree().get_nodes_in_group(enemy_group):
		if not (enemy is Node2D):
			continue

		var enemy_2d := enemy as Node2D
		var dist := attacker.global_position.distance_to(enemy_2d.global_position)
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy_2d

	if nearest_enemy != null and nearest_enemy.has_method("take_damage"):
		nearest_enemy.take_damage(attack_damage)

	return nearest_enemy
