extends CharacterBody2D
class_name Worm

const BASE_HEALTH: float = 30.0
const BASE_SPEED: float = 85.0
const MIN_WAIT_TIME: float = 1.0
const MAX_WAIT_TIME: float = 4.0
const CONFUSED_TIME: float = 3.0
const KNOCKBACK_FORCE: float = 650.0
const DAMAGE: int = 25

enum State {WAITING, ARISING, HITTING_GROUND, GETTING_UP, CONFUSED, DIVING}

var _health: float = BASE_HEALTH
var _state: State = State.WAITING
var _player: Player = null
var _speed: float = BASE_SPEED

var shockwave_scene: PackedScene = preload("res://Scenes/Enemies/Worm/Shockwave.tscn")

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	$WaitTimer.start(MAX_WAIT_TIME)
	visible = false


func _find_player() -> void:
	_player = get_parent().get_node_or_null("Player")


func _trigger_shockwave() -> void:
	var shockwave: Area2D = shockwave_scene.instantiate()
	shockwave.global_position = Vector2(self.global_position.x + 20.0, self.global_position.y + 65.0)
	shockwave.z_index = -1
	shockwave.knockback_force = KNOCKBACK_FORCE
	shockwave.damage = DAMAGE
	get_tree().current_scene.add_child(shockwave)


func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO, _knockback_force: float = 0.0) -> void:
	_health -= damage
	
	if _animated_sprite:
		_animate_blink()
	
	if _health <= 0:
		queue_free()


func _animate_blink() -> void:
	var original_color = _animated_sprite.self_modulate
	var tween = create_tween()
	tween.set_parallel(false)  # Sequential animations
	
	for i in range(4):
		tween.tween_property(_animated_sprite, "self_modulate", Color.RED, 0.08)
		tween.tween_property(_animated_sprite, "self_modulate", original_color, 0.08)


func _on_animated_sprite_2d_animation_finished() -> void:
	if _state == State.ARISING:
		_state = State.HITTING_GROUND
		$AnimatedSprite2D.play("hit_ground")
	elif _state == State.HITTING_GROUND:
		_trigger_shockwave()
		_state = State.GETTING_UP
		$AnimatedSprite2D.play("getting_up")
	elif _state == State.GETTING_UP:
		_state = State.CONFUSED
		$AnimatedSprite2D.play("confused")
		$ConfusedTimer.start(CONFUSED_TIME)
	elif _state == State.DIVING:
		visible = false
		_state = State.WAITING
		$WaitTimer.start(randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME))


func _on_wait_timer_timeout() -> void:
	_find_player()
	
	if _player == null:
		_state = State.WAITING
		$WaitTimer.start(randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME))
	else:
		# We choose a random point to spawn aound the player
		var angle: float = randf_range(0, TAU)  # TAU = 2 * PI, angle is between 0° et 360°
		var distance: float = randf_range(50, 150)
		var offset := Vector2.from_angle(angle) * distance
		global_position = _player.global_position + offset
		_state = State.ARISING
		visible = true
		$AnimatedSprite2D.play("arise")


func _on_confused_timer_timeout() -> void:
	_state = State.DIVING
	$AnimatedSprite2D.play("dive")
