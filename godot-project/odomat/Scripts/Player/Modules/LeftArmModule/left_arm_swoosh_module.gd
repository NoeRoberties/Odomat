class_name LeftArmSwooshModule
extends PlayerModule


const ATTACK_RANGE: float = 100.0
const ATTACK_ARC_DEG: float = 155.0
const ATTACK_DAMAGE: int = 1
const ATTACK_COOLDOWN: float = 0.4
const KNOCKBACK_FORCE: float = 300.0
const SWOOSH_SCRIPT := preload("res://Scripts/Player/swoosh.gd")

var _cooldown_remaining: float = 0.0
var _attack_area: Area2D = null


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _ready() -> void:
	_setup_attack_area()


func on_unequip(_player: CharacterBody2D) -> void:
	if _attack_area != null and is_instance_valid(_attack_area):
		_attack_area.queue_free()
		_attack_area = null


func _setup_attack_area() -> void:
	var player := get_parent() as CharacterBody2D
	if player == null:
		return

	_attack_area = Area2D.new()
	_attack_area.name = "MeleeAttackArea"
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 1
	_attack_area.monitoring = true
	_attack_area.monitorable = false

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ATTACK_RANGE
	shape.shape = circle
	_attack_area.add_child(shape)

	player.add_child(_attack_area)


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
	if GameState.current_state != GameState.GameState.PLAYING:
		return

	var mouse_world: Vector2 = player.get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_world - player.global_position)
	if attack_dir.length_squared() == 0.0:
		attack_dir = Vector2.RIGHT
	else:
		attack_dir = attack_dir.normalized()

	for enemy in _get_enemies_in_attack_arc(player, attack_dir):
		if enemy.has_method("take_damage"):
			enemy.take_damage(ATTACK_DAMAGE, attack_dir * KNOCKBACK_FORCE)

	_spawn_swoosh(player, attack_dir)


func _get_enemies_in_attack_arc(player: CharacterBody2D, attack_dir: Vector2) -> Array[Node2D]:
	if _attack_area == null or not is_instance_valid(_attack_area):
		return []

	var enemies_in_arc: Array[Node2D] = []
	var arc_threshold := cos(deg_to_rad(ATTACK_ARC_DEG * 0.5))

	for body in _attack_area.get_overlapping_bodies():
		if not (body is Node2D):
			continue
		var enemy := body as Node2D
		if not enemy.is_in_group("enemies"):
			continue

		var to_enemy := enemy.global_position - player.global_position
		if to_enemy.length_squared() == 0.0:
			continue

		var enemy_dir := to_enemy.normalized()
		if attack_dir.dot(enemy_dir) < arc_threshold:
			continue

		enemies_in_arc.append(enemy)

	return enemies_in_arc


func _spawn_swoosh(player: CharacterBody2D, attack_dir: Vector2) -> void:
	var swoosh := Node2D.new()
	swoosh.set_script(SWOOSH_SCRIPT)
	player.get_parent().add_child(swoosh)
	swoosh.global_position = player.global_position
	swoosh.play(attack_dir)
