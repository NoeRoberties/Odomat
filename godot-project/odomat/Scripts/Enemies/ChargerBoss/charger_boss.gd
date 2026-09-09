extends CharacterBody2D
class_name ChargerBoss

const MAX_HEALTH: float = 100.0
const PHASE2_HP_THRESHOLD: float = 50.0

# Phase 1 Parameters
const CHARGE_SPEED: float = 850.0 # Faster high-speed charging
const CHARGE_SELF_DAMAGE: float = 1.375 # Takes ~36 charges (twice as many!) to go from 100 to 50 HP
const CHARGE_CONTACT_DAMAGE: int = 15
const CHARGE_KNOCKBACK_FORCE: float = 280.0
const PIVOT_DURATION: float = 0.35 # Pause duration on wall impact for recovery & impact shake


# Phase 2 Parameters
const SALVO_INTERVAL: float = 1.8
const BULLETS_PER_SALVO: int = 12
const SALVO_ROTATION_STEP: float = 0.35 # ~20 degrees rotation step per wave

enum Phase { PHASE1_CHARGING, PHASE2_TURRET }
enum State { CHARGE, PIVOT, TURRET_IDLE, TURRET_FIRING }

@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/ChargerBoss/BossProjectile.tscn")
@export var arena_room_size: Vector2 = Vector2(970.0, 670.0)

var _current_phase: Phase = Phase.PHASE1_CHARGING
var _state: State = State.CHARGE
var _health: float = MAX_HEALTH
var _spawn_origin: Vector2 = Vector2.ZERO

var _charge_direction: Vector2 = Vector2.RIGHT
var _pivot_timer: float = 0.0

var _salvo_timer: float = 0.0
var _salvo_angle_offset: float = 0.0
var _player: CharacterBody2D = null

var _visual: CanvasItem
var _original_color: Color
var _blink_tween: Tween
var _impact_tween: Tween

const COLOR_PHASE1_CHARGE: Color = Color(1.0, 0.8, 0.0)   # Electric Gold/Yellow
const COLOR_PHASE1_PIVOT: Color  = Color(1.0, 0.5, 0.0)   # Orange Flash
const COLOR_PHASE2_VULNERABLE: Color = Color(0.2, 0.9, 1.0) # Vulnerable Cyan
const COLOR_PHASE2_FIRING: Color = Color(1.0, 0.1, 0.2)   # Crimson Red


func _ready() -> void:
	_spawn_origin = global_position
	_visual = get_node_or_null("Visual") as CanvasItem
	if _visual and _visual is Control:
		(_visual as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _visual:
		_original_color = COLOR_PHASE1_CHARGE
		_visual.modulate = COLOR_PHASE1_CHARGE
	_setup_visual_arena_room()
	_pick_random_charge_direction()
	_find_player()



func _setup_visual_arena_room() -> void:
	var room_node = Node2D.new()
	room_node.name = "BossArenaVisual"
	room_node.global_position = _spawn_origin

	# Floor surface background
	var floor_rect = ColorRect.new()
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_rect.size = arena_room_size
	floor_rect.position = -arena_room_size / 2.0
	floor_rect.color = Color(0.1, 0.08, 0.18, 0.2)
	room_node.add_child(floor_rect)


	# Wall border outline
	var line = Line2D.new()
	line.width = 6.0
	line.default_color = Color(1.0, 0.55, 0.1, 0.85)

	var half := arena_room_size / 2.0
	line.add_point(Vector2(-half.x, -half.y))
	line.add_point(Vector2(half.x, -half.y))
	line.add_point(Vector2(half.x, half.y))
	line.add_point(Vector2(-half.x, half.y))
	line.add_point(Vector2(-half.x, -half.y))
	room_node.add_child(line)

	var parent := get_parent()
	if parent:
		parent.call_deferred("add_child", room_node)


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return

	if _current_phase == Phase.PHASE1_CHARGING:
		_process_phase1(delta)
	else:
		_process_phase2(delta)


func _get_arena_rect() -> Rect2:
	var half := arena_room_size / 2.0
	return Rect2(_spawn_origin - half, arena_room_size)


func _process_phase1(delta: float) -> void:
	match _state:
		State.CHARGE:
			velocity = _charge_direction * CHARGE_SPEED
			_set_visual_color(COLOR_PHASE1_CHARGE)
			move_and_slide()
			_apply_phase1_contact_damage()

			var arena_rect := _get_arena_rect()
			var radius: float = 22.0
			var min_x := arena_rect.position.x + radius
			var max_x := arena_rect.end.x - radius
			var min_y := arena_rect.position.y + radius
			var max_y := arena_rect.end.y - radius

			var hit_wall := false
			var hit_normal := Vector2.ZERO

			if global_position.x <= min_x:
				global_position.x = min_x
				hit_wall = true
				hit_normal = Vector2.RIGHT
			elif global_position.x >= max_x:
				global_position.x = max_x
				hit_wall = true
				hit_normal = Vector2.LEFT

			if global_position.y <= min_y:
				global_position.y = min_y
				hit_wall = true
				hit_normal = Vector2.DOWN
			elif global_position.y >= max_y:
				global_position.y = max_y
				hit_wall = true
				hit_normal = Vector2.UP

			if hit_wall:
				_complete_charge_leg(hit_normal)

		State.PIVOT:
			velocity = Vector2.ZERO
			_pivot_timer -= delta
			if _pivot_timer <= 0.0:
				_pick_random_charge_direction()
				_state = State.CHARGE


func _complete_charge_leg(hit_normal: Vector2 = Vector2.ZERO) -> void:
	# Deplete self HP per charge leg (wall impact)
	_health -= CHARGE_SELF_DAMAGE
	DamageNumbers.display_number(CHARGE_SELF_DAMAGE, global_position + Vector2(0, -25), Color(1.0, 0.55, 0.1))
	_play_wall_bounce_animation(hit_normal)

	if _health <= PHASE2_HP_THRESHOLD:
		_transition_to_phase2()
	else:
		_state = State.PIVOT
		_pivot_timer = PIVOT_DURATION



func _play_wall_bounce_animation(hit_normal: Vector2) -> void:
	if _visual:
		_visual.scale = Vector2(1.0, 1.0)
		_visual.position = Vector2(-20.0, -20.0)

	if _impact_tween:
		_impact_tween.kill()

	# Rebound knockback away from wall
	var kb_target := global_position + hit_normal * 28.0
	_impact_tween = create_tween()

	# Red self-damage flash
	if _visual:
		_impact_tween.parallel().tween_property(_visual, "modulate", Color(1.0, 0.2, 0.2), 0.06)
		_impact_tween.chain().tween_property(_visual, "modulate", COLOR_PHASE1_PIVOT, 0.15)

	# Smooth knockback position rebound off wall
	_impact_tween.parallel().tween_property(self, "global_position", kb_target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)




func _pick_random_charge_direction() -> void:
	if _player == null:
		_find_player()

	if _player != null:
		var dir := (_player.global_position - global_position)
		if dir.length_squared() > 1.0:
			_charge_direction = dir.normalized()
			return

	# Fallback if player not found
	_charge_direction = Vector2.from_angle(randf() * TAU)



func _apply_phase1_contact_damage() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(CHARGE_CONTACT_DAMAGE, global_position, CHARGE_KNOCKBACK_FORCE)
			break


func _transition_to_phase2() -> void:
	_current_phase = Phase.PHASE2_TURRET
	_state = State.TURRET_IDLE
	_health = PHASE2_HP_THRESHOLD
	velocity = Vector2.ZERO
	_salvo_timer = 0.5 # Short pause before first salvo
	_set_visual_color(COLOR_PHASE2_VULNERABLE)


func _process_phase2(delta: float) -> void:
	velocity = Vector2.ZERO
	_salvo_timer += delta

	if _salvo_timer >= SALVO_INTERVAL:
		_fire_rotating_salvo()
		_salvo_timer = 0.0


func _fire_rotating_salvo() -> void:
	if projectile_scene == null:
		return

	_state = State.TURRET_FIRING
	_set_visual_color(COLOR_PHASE2_FIRING)

	_salvo_angle_offset += SALVO_ROTATION_STEP
	var angle_step := TAU / float(BULLETS_PER_SALVO)

	for i in range(BULLETS_PER_SALVO):
		var bullet_angle := _salvo_angle_offset + float(i) * angle_step
		var bullet = projectile_scene.instantiate() as BossProjectile
		bullet.global_position = global_position
		bullet.direction = Vector2.from_angle(bullet_angle)
		get_parent().add_child(bullet)

	# Brief visual feedback for salvo blast, then return to vulnerable color
	await get_tree().create_timer(0.2).timeout
	if _current_phase == Phase.PHASE2_TURRET and _health > 0:
		_state = State.TURRET_IDLE
		_set_visual_color(COLOR_PHASE2_VULNERABLE)


func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	# Phase 1: High speed makes boss immune to direct player hits
	if _current_phase == Phase.PHASE1_CHARGING:
		return

	# Phase 2: Static turret takes damage from player
	_health -= damage
	DamageNumbers.display_number(damage, global_position + Vector2(0, -25))
	_animate_blink()

	if _health <= 0:
		queue_free()



func _set_visual_color(color: Color) -> void:
	if _visual:
		_visual.modulate = color


func _animate_blink() -> void:
	if _visual == null:
		return
	if _blink_tween:
		_blink_tween.kill()

	var current_col := _visual.modulate
	_blink_tween = create_tween()
	_blink_tween.set_parallel(false)

	for i in range(3):
		_blink_tween.tween_property(_visual, "modulate", Color.RED, 0.08)
		_blink_tween.tween_property(_visual, "modulate", current_col, 0.08)
