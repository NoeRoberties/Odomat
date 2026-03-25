class_name LeftArmSwooshModule
extends PlayerModule


const ATTACK_RANGE: float = 100.0
const ATTACK_DAMAGE: int = 1
const ATTACK_COOLDOWN: float = 0.4
const KNOCKBACK_FORCE: float = 300.0
const SWOOSH_SCRIPT := preload("res://Scripts/Player/swoosh.gd")

var _cooldown_remaining: float = 0.0


func handle_process(_player: CharacterBody2D, delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if _cooldown_remaining > 0.0:
		return
	var player = get_parent()
	if player == null:
		return
	_cooldown_remaining = ATTACK_COOLDOWN
	_do_attack(player)


func _do_attack(player: CharacterBody2D) -> void:
	var mouse_world: Vector2 = player.get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_world - player.global_position).normalized()

	var nearest_enemy: Node2D = null
	var nearest_dist: float = ATTACK_RANGE
	
	# Half arc angle in radians (155° / 2 = 77.5°)
	var arc_half_radians = deg_to_rad(155.0 / 2.0)
	var arc_threshold = cos(arc_half_radians)  # ≈ 0.22
	
	var enemy_list = player.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemy_list:
		if not (enemy is Node2D):
			continue
		var enemy_node: Node2D = enemy
		var dist := player.global_position.distance_to(enemy_node.global_position)
		
		
		# Check if enemy is within arc range (directional validation)
		if dist <= ATTACK_RANGE:
			var enemy_dir = (enemy_node.global_position - player.global_position).normalized()
			var dot_product = attack_dir.dot(enemy_dir)
			
			
			# Only consider enemies within the swoosh arc
			if dot_product >= arc_threshold and dist <= nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy_node

	if nearest_enemy != null and nearest_enemy.has_method("take_damage"):
		nearest_enemy.take_damage(ATTACK_DAMAGE, attack_dir * KNOCKBACK_FORCE)
	else:
		print("No valid enemy target found")

	_spawn_swoosh(player, attack_dir)


func _spawn_swoosh(player: CharacterBody2D, attack_dir: Vector2) -> void:
	var swoosh := Node2D.new()
	swoosh.set_script(SWOOSH_SCRIPT)
	player.get_parent().add_child(swoosh)
	swoosh.global_position = player.global_position
	swoosh.play(attack_dir)
