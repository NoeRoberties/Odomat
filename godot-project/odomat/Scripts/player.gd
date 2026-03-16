extends CharacterBody2D

## ── Valeurs de base du robot (sans aucun module équipé) ──────────────────────
const BASE_SPEED          : float = 150.0
const BASE_ATTACK_RANGE   : float = 100.0
const BASE_ATTACK_DAMAGE  : int   = 1
const BASE_ATTACK_COOLDOWN: float = 0.4

const ISO_DIRS: Dictionary = {
	"ui_up":    Vector2(0.0, -1.0),
	"ui_right": Vector2(1.0, 0.0),
	"ui_down":  Vector2(0.0, 1.0),
	"ui_left":  Vector2(-1.0, 0.0),
}

const SwooshScript := preload("res://Scripts/swoosh.gd")

var _cooldown_remaining: float = 0.0


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _physics_process(_delta: float) -> void:
	var move_dir := Vector2.ZERO

	for action: String in ISO_DIRS:
		if Input.is_action_pressed(action):
			move_dir += ISO_DIRS[action]

	velocity = move_dir.normalized() * BASE_SPEED if move_dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = BASE_ATTACK_COOLDOWN
			_do_attack()


func _do_attack() -> void:
	# Direction = joueur → souris en coordonnées monde.
	var mouse_world: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_world - global_position).normalized()

	var nearest_enemy: Node2D = null
	var nearest_dist: float = BASE_ATTACK_RANGE

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist: float = position.distance_to((enemy as Node2D).position)
		if dist <= nearest_dist:
			nearest_dist  = dist
			nearest_enemy = enemy

	if nearest_enemy != null:
		nearest_enemy.take_damage(BASE_ATTACK_DAMAGE)

	_spawn_swoosh(attack_dir)


func _spawn_swoosh(attack_dir: Vector2) -> void:
	var swoosh := Node2D.new()
	swoosh.set_script(SwooshScript)
	get_parent().add_child(swoosh)
	swoosh.global_position = global_position
	swoosh.play(attack_dir)
