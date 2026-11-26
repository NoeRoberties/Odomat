class_name RightArmIdleModule
extends Module

const SWOOSH_SCENE: PackedScene = preload("res://Scenes/Player/WeaponEffects/SwordSwoosh.tscn")

const COMBO_DAMAGE: Array[int] = [1, 1, 1, 3]
const COMBO_KNOCKBACK: Array[float] = [0.0, 0.0, 0.0, 350.0]
const COMBO_RANGE: Array[float] = [40.0, 40.0, 40.0, 45.0]
const COMBO_SWOOSH_SCALE: Array[float] = [0.75, 0.5, 0.5, 0.5]
const COMBO_COOLDOWN: Array[float] = [0.18, 0.18, 0.2, 0.75]
const STRONG_HIT_INDEX: int = 3
const COMBO_WINDOW: float = 0.3

@export var attack_speed: float = 1.0

var _cooldown_remaining = 0.0
var _combo_step: int = 0
var _combo_timer: float = 0.0
var _attack_buffered := false
var _attacking = false
var _last_move_dir: Vector2 = Vector2.DOWN
var _last_device_is_gamepad := false


func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_sprite.animation = "walk_left"
	_original_color = _sprite.self_modulate


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _cooldown_remaining <= 0.0:
		if _attack_buffered:
			_attack_buffered = false
			_try_attack()
		else:
			_combo_timer = maxf(_combo_timer - delta, 0.0)
			if _combo_timer <= 0.0:
				_combo_step = 0


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_device_is_gamepad = true
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		_last_device_is_gamepad = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sword_attack"):
		if _cooldown_remaining <= 0.0:
			_try_attack()
		else:
			_attack_buffered = true


func _try_attack() -> void:
	var player = get_parent()
	if player == null:
		return
	var step := _combo_step
	_cooldown_remaining = COMBO_COOLDOWN[step] / maxf(attack_speed, 0.01)
	_combo_timer = COMBO_WINDOW
	_combo_step = (step + 1) % COMBO_DAMAGE.size()
	_do_attack(player, step)


func _do_attack(player: CharacterBody2D, step: int) -> void:
	_attacking = true
	if _last_move_dir.x <= 0.0:
		_sprite.play("attack_left")
	else:
		_sprite.play("attack_right")
	_sprite.frame = 0
	_spawn_swoosh(player, step)


func _get_attack_direction(player: CharacterBody2D) -> Vector2:
	if _last_device_is_gamepad:
		if _last_move_dir != Vector2.ZERO:
			return _last_move_dir.normalized()
		return Vector2.DOWN

	var mouse_pos = player.get_global_mouse_position()
	return (mouse_pos - self.global_position).normalized()


func _spawn_swoosh(player: CharacterBody2D, step: int) -> void:
	var swoosh := SWOOSH_SCENE.instantiate()
	var direction := _get_attack_direction(player)

	swoosh.global_position = self.global_position + direction * COMBO_RANGE[step]
	swoosh.rotation = direction.angle() + PI
	swoosh.scale *= COMBO_SWOOSH_SCALE[step]
	player.get_parent().add_child(swoosh)
	swoosh.trigger_hit(COMBO_DAMAGE[step], player.global_position, COMBO_KNOCKBACK[step], step, step == STRONG_HIT_INDEX)


func update_animation(move_dir: Vector2) -> void:
	if _attacking:
		return
	if move_dir == Vector2.ZERO:
		_sprite.stop()
		return
	if move_dir.x < 0.0:
		_sprite.play("walk_left")
		_last_move_dir = move_dir
		return
	if move_dir.x > 0.0:
		_sprite.play("walk_right")
		_last_move_dir = move_dir
		return
	if move_dir.y > 0.0:
		_sprite.play()
		_last_move_dir = move_dir
		return
	if move_dir.y < 0.0:
		_sprite.play()
		_last_move_dir = move_dir
		return


func _on_animated_sprite_2d_animation_finished() -> void:
	_attacking = false
	if _last_move_dir.x <= 0.0:
		_sprite.play("walk_left")
	else:
		_sprite.play("walk_right")
