extends CharacterBody2D

## ── Valeurs de base du robot (sans aucun module équipé) ──────────────────────
const BASE_SPEED          : float = 150.0
const BASE_ATTACK_RANGE   : float = 100.0
const BASE_ATTACK_DAMAGE  : int   = 1
const BASE_ATTACK_COOLDOWN: float = 0.4

const ISO_DIRS: Dictionary = {
	"move_up":    Vector2( 0.0, -1.0),
	"move_right": Vector2( 1.0,  0),
	"move_down":  Vector2(0.0,  1.0),
	"move_left":  Vector2(-1.0, 0.0),
}

const SwooshScript := preload("res://Scripts/Player/swoosh.gd")
const DefaultWeaponScript := preload("res://Scripts/Player/Modules/Attacks/basic_weapon.gd")

var _cooldown_remaining: float = 0.0
var _npc_to_interact: NPC = null
var _weapon: Weapon


func _ready() -> void:
	RobotModules.module_equipped.connect(_on_module_equipped)
	RobotModules.module_unequipped.connect(_on_module_unequipped)
	_refresh_weapon()


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
			_cooldown_remaining = _weapon.get_attack_cooldown()
			_do_attack()
	
	if event.is_action_pressed("interact_npc") and _npc_to_interact != null:
		_npc_to_interact._launch_dialogue()
		


func _do_attack() -> void:
	# Direction = joueur → souris en coordonnées monde.
	var mouse_world: Vector2 = get_global_mouse_position()
	var attack_dir: Vector2 = (mouse_world - global_position).normalized()

	_weapon.attack(self)

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


func _on_module_equipped(slot: String, _module: ModuleData) -> void:
	if slot == "right_arm":
		_refresh_weapon()


func _on_module_unequipped(slot: String) -> void:
	if slot == "right_arm":
		_refresh_weapon()


func _refresh_weapon() -> void:
	var right_arm_module: ModuleData = RobotModules.equipped["right_arm"]
	var next_weapon: Weapon = null

	if right_arm_module != null:
		next_weapon = right_arm_module.create_weapon_instance()

	if next_weapon == null:
		next_weapon = DefaultWeaponScript.new()

	next_weapon.configure_from_module(
		right_arm_module,
		BASE_ATTACK_RANGE,
		BASE_ATTACK_DAMAGE,
		BASE_ATTACK_COOLDOWN
	)
	_weapon = next_weapon
