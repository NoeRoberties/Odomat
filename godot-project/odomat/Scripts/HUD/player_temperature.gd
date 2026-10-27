extends CanvasLayer

@onready var _bar: Control = $Control/Life_progress_bar

const MIN_BAR_VALUE: int = 20
const MAX_BAR_VALUE: int = 100
const ANIMATION_DURATION: float = 0.3

const DAMAGED_TRESHOLD: float = 0.35
const CRITICAL_TRESHOLD: float = 0.8

var _health_tween: Tween
var _avatar: AnimatedSprite2D

func _ready() -> void:
	_avatar = $Control/Life_progress_bar/Avatar
	_avatar.play("normal")
	
	# Position the life bar centered at bottom
	_bar.anchor_left = 1.0
	_bar.anchor_right = 0.01
	_bar.anchor_top = 0.78
	_bar.anchor_bottom = 1.0
	
	_bar.scale = Vector2(1.5, 1.5)

	# Setup bar as inverted thermometer (min fill at max health, max fill at min health)
	_bar.min_value = MIN_BAR_VALUE
	_bar.max_value = MAX_BAR_VALUE
	_bar.value = MIN_BAR_VALUE

	# Try to find the player by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_connect_to_player(players[0])
	else:
		call_deferred("_find_player_later")

func _find_player_later() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_connect_to_player(players[0])

func _connect_to_player(player: Node) -> void:
	if player.has_signal("health_changed"):
		player.connect("health_changed", Callable(self, "_on_health_changed"))
		_on_health_changed(player.get("_health"), player.get("max_health"))

func _on_health_changed(current: int, maximum: int) -> void:
	# Invert the health value: low health = high bar, high health = low bar
	# Formula: bar_value = max - (current / max) * (max - min)
	var inverted_value = MAX_BAR_VALUE - (float(current) / float(maximum)) * (MAX_BAR_VALUE - MIN_BAR_VALUE)
	
	if inverted_value / MAX_BAR_VALUE >= CRITICAL_TRESHOLD:
		_avatar.play("critical")
	elif inverted_value / MAX_BAR_VALUE >= DAMAGED_TRESHOLD:
		_avatar.play("damaged")
	else:
		_avatar.play("normal")
	
	# Kill previous tween if still running
	if _health_tween:
		_health_tween.kill()
	
	# Animate the bar value smoothly
	_health_tween = create_tween()
	_health_tween.set_trans(Tween.TRANS_SINE)
	_health_tween.set_ease(Tween.EASE_OUT)
	_health_tween.tween_property(_bar, "value", inverted_value, ANIMATION_DURATION)
