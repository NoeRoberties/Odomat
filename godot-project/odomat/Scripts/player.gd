extends CharacterBody2D

const SPEED: float = 150.0

const ISO_DIRS: Dictionary = {
	"move_up":    Vector2( 0.0, -1.0),
	"move_right": Vector2( 1.0,  0),
	"move_down":  Vector2(0.0,  1.0),
	"move_left":  Vector2(-1.0, 0.0),
}

## Portée d'attaque en pixels écran.
const ATTACK_RANGE: float = 100.0
## Dégâts infligés par coup.
const ATTACK_DAMAGE: int = 1
## Cooldown entre deux attaques (secondes).
const ATTACK_COOLDOWN: float = 0.4
## Script du swoosh, instancié dynamiquement à chaque attaque.
const SwooshScript := preload("res://Scripts/swoosh.gd")

var _cooldown_remaining: float = 0.0
var _npc_to_interact: NPC = null


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _physics_process(_delta: float) -> void:
	var move_dir := Vector2.ZERO

	for action: String in ISO_DIRS:
		if Input.is_action_pressed(action):
			move_dir += ISO_DIRS[action]

	velocity = move_dir.normalized() * SPEED if move_dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = ATTACK_COOLDOWN
			_do_attack()
	
	if event.is_action_pressed("interact_npc") and _npc_to_interact != null:
		_npc_to_interact._launch_dialogue()
		


func _do_attack() -> void:
	# Direction = joueur → souris en coordonnées monde.
	var mouse_world: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_world - global_position).normalized()

	var nearest_enemy: Node2D = null
	var nearest_dist: float = ATTACK_RANGE

	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist: float = position.distance_to((enemy as Node2D).position)
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy

	if nearest_enemy != null:
		nearest_enemy.take_damage(ATTACK_DAMAGE)

	_spawn_swoosh(attack_dir)


func _spawn_swoosh(attack_dir: Vector2) -> void:
	var swoosh := Node2D.new()
	swoosh.set_script(SwooshScript)
	get_parent().add_child(swoosh)
	swoosh.global_position = global_position
	swoosh.play(attack_dir)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is NPC:
		_npc_to_interact = body


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == _npc_to_interact:
		_npc_to_interact = null
