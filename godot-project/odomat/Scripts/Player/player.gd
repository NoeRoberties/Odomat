extends CharacterBody2D
@onready var dash_timer: Timer = $DashTimer
@onready var dash_again_timer: Timer = $DashAgainTimer
@onready var dash_bar_1: TextureProgressBar = $DashUI/DashBar1
@onready var dash_bar_2: TextureProgressBar = $DashUI/DashBar2

const BASE_SPEED          : float = 150.0
const BASE_ATTACK_RANGE   : float = 100.0
const BASE_ATTACK_DAMAGE  : int   = 1
const BASE_ATTACK_COOLDOWN: float = 0.4
const DASH_SPEED          : float = 300.0
const MAX_DASH            : int = 2


const ISO_DIRS: Dictionary = {
	"move_up":    Vector2( 0.0, -1.0),
	"move_right": Vector2( 1.0,  0),
	"move_down":  Vector2(0.0,  1.0),
	"move_left":  Vector2(-1.0, 0.0),
}

const SwooshScript := preload("res://Scripts/Player/swoosh.gd")
const EquipmentMenuScene: PackedScene = preload("res://Scenes/UI/EquipmentMenu/EquipmentMenu.tscn")

var _cooldown_remaining: float = 0.0
var _npc_to_interact: NPC = null
var _dashing               : bool = false
var _dash_count            : int = 0

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	update_dash_ui()


func update_dash_ui() -> void:

	var progress = 0.0
	if !dash_again_timer.is_stopped():
		progress = 1.0 - (dash_again_timer.time_left / dash_again_timer.wait_time)

	if _dash_count == 0:
		dash_bar_1.value = 1.0
		dash_bar_2.value = 1.0
	elif _dash_count == 1:
		dash_bar_1.value = 1.0
		dash_bar_2.value = progress
	elif _dash_count == 2:
		dash_bar_1.value = progress
		dash_bar_2.value = 0.0


func _physics_process(_delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	var move_dir := Vector2.ZERO

	for action: String in ISO_DIRS:
		if Input.is_action_pressed(action):
			move_dir += ISO_DIRS[action]

	if Input.is_action_just_pressed("dash") and _dash_count < MAX_DASH and move_dir != Vector2.ZERO:
		_dash_count += 1
		_dashing = true
		dash_timer.start()
		if dash_again_timer.is_stopped():
			dash_again_timer.start()
	
	var current_speed = DASH_SPEED if _dashing else BASE_SPEED
	velocity = move_dir.normalized() * current_speed if move_dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = BASE_ATTACK_COOLDOWN
			_do_attack()
	
	if event.is_action_pressed("interact_npc") and _npc_to_interact != null:
		_npc_to_interact._launch_dialogue()
	
	if event.is_action_pressed("open_inventory"):
		add_child(EquipmentMenuScene.instantiate())


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

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is NPC:
		_npc_to_interact = body


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == _npc_to_interact:
		_npc_to_interact = null


func _on_dash_timer_timeout() -> void:
	_dashing = false


func _on_dash_again_timer_timeout() -> void:
	if _dash_count > 0:
		_dash_count -= 1
		if _dash_count > 0:
			dash_again_timer.start()
	
