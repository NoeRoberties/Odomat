class_name RightArmIdleModule
extends Module

const ATTACK_DAMAGE: int = 1
const KNOCKBACK_FORCE: float = 200.0
const ATTACK_COOLDOWN: float = 0.4
const SWOOSH_RANGE = 50.0
const SWOOSH_SCENE: PackedScene = preload("res://Scenes/Player/WeaponEffects/SwordSwoosh.tscn")

var _cooldown_remaining = 0.0
var _attacking = false
var _last_move_dir: Vector2

func _ready() -> void:
	_sprite = $AnimatedSprite2D
	_sprite.animation = "walk_left"

func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sword_attack") and _cooldown_remaining <= 0.0:
		var player = get_parent()
		if player == null:
			return
		_cooldown_remaining = ATTACK_COOLDOWN
		_do_attack(player)


func _do_attack(player: CharacterBody2D) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	
	_attacking = true
	if _last_move_dir.x <= 0.0:
		_sprite.play("attack_left")
	else:
		_sprite.play("attack_right")
	_spawn_swoosh(player)


func _spawn_swoosh(player: CharacterBody2D) -> void:
	var swoosh := SWOOSH_SCENE.instantiate()
	var mouse_pos = player.get_global_mouse_position()
	var direction = (self.global_position - mouse_pos).normalized()
	
	swoosh.global_position = self.global_position - direction * SWOOSH_RANGE
	swoosh.rotation = direction.angle()
	player.get_parent().add_child(swoosh)
	swoosh.trigger_hit(ATTACK_DAMAGE, player.global_position, KNOCKBACK_FORCE)

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
		return
	if move_dir.y < 0.0:
		_sprite.play()
		return


func _on_animated_sprite_2d_animation_finished() -> void:
	_attacking = false
	if _last_move_dir.x <= 0.0:
		_sprite.play("walk_left")
	else:
		_sprite.play("walk_right")
