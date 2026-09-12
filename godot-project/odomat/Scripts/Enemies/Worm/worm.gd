extends Enemy
class_name Worm

const WORM_HEALTH: int = 30
const MIN_WAIT_TIME: float = 1.0
const MAX_WAIT_TIME: float = 4.0
const CONFUSED_TIME: float = 3.0
const KNOCKBACK_FORCE: float = 650.0
const DAMAGE: int = 25

enum State {WAITING, ARISING, HITTING_GROUND, GETTING_UP, CONFUSED, DIVING}

var _state: State = State.WAITING
var _player: Player = null

var shockwave_scene: PackedScene = preload("res://Scenes/Enemies/Worm/Shockwave.tscn")

func _on_ready() -> void:
	_health = WORM_HEALTH
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


func _on_animated_sprite_2d_animation_finished() -> void:
	if _state == State.ARISING:
		_state = State.HITTING_GROUND
		_animated_sprite.play("hit_ground")
	elif _state == State.HITTING_GROUND:
		_trigger_shockwave()
		_state = State.GETTING_UP
		_animated_sprite.play("getting_up")
	elif _state == State.GETTING_UP:
		_state = State.CONFUSED
		_animated_sprite.play("confused")
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
		_animated_sprite.play("arise")


func _on_confused_timer_timeout() -> void:
	_state = State.DIVING
	_animated_sprite.play("dive")
