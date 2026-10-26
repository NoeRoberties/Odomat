class_name  Enemy
extends CharacterBody2D

const DEFAULT_HEALTH = 10.0

const HEALTH_BAR_SCENE = preload("res://Scenes/HUD/EnemyHealthBar.tscn")

var _health: int = DEFAULT_HEALTH
var _animated_sprite: AnimatedSprite2D
var _original_color: Color
var _blink_tween: Tween
var _health_bar: EnemyHealthBar
var _immune: bool

func _ready() -> void:
	_immune = false
	_animated_sprite = get_node_or_null("AnimatedSprite2D")
	if _animated_sprite == null:
		queue_free()
	_original_color = _animated_sprite.modulate
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	_place_health_bar()
	_on_ready()
	_health_bar.setMaxHP(_health)
	add_child(_health_bar)


## Override this function to add instructions to the _ready function of the Enemy base class
func _on_ready() -> void:
	return


func _physics_process(delta: float) -> void:
	_on_physics_process(delta)


## Override this function to add instructions to the _physics_process function of the Enemy base class 
func _on_physics_process(_delta: float) -> void:
	return


## Call this function to make the enemy instance untouchable
func _gain_immunity() -> void:
	_health_bar.hide()
	_immune = true


## Call this function to make the enemy instance touchable by player attacks
func _loose_immunity() -> void:
	_health_bar.show()
	_immune = false


## Call this function to make the enemy loose health and apply a knockback
func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if _immune:
		return
	_health -= damage
	_health_bar.update_health(_health)
	
	if _health <= 0:
		queue_free()
	
	# Visual feedback: blinking effect
	if _animated_sprite:
		_animate_blink()
	
	_on_damage(damage, attacker_position, knockback_force)


## Override this function to add instructions to when the enemy take damage.
## It is useful for knockback handling.
func _on_damage(damage: int, attacker_position: Vector2, knockback_force: float) -> void:
	return


## Overrite this function to choose health bar placement
func _place_health_bar() -> void:
	_health_bar.position = Vector2.ZERO


## Function to make the enemy sprite blink in red 
func _animate_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()

	_animated_sprite.self_modulate = _original_color
	
	_blink_tween = create_tween()
	_blink_tween.set_parallel(false)  # Sequential animations
	
	for i in range(4):
		_blink_tween.tween_property(_animated_sprite, "self_modulate", Color.RED, 0.08)
		_blink_tween.tween_property(_animated_sprite, "self_modulate", _original_color, 0.08)
