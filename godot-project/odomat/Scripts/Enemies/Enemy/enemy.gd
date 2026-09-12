class_name  Enemy
extends CharacterBody2D

const DEFAULT_HEALTH = 10.0

var _health: int = DEFAULT_HEALTH
var _animated_sprite: AnimatedSprite2D
var _original_color: Color
var _blink_tween: Tween

func _ready() -> void:
	_animated_sprite = get_node_or_null("AnimatedSprite2D")
	if _animated_sprite == null:
		queue_free()
	_original_color = _animated_sprite.modulate
	_on_ready()


## Override this function to add instructions to the _ready function of the Enemy base class
func _on_ready() -> void:
	return


func _physics_process(delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	_on_physics_process(delta)


## Override this function to add instructions to the _physics_process function of the Enemy base class 
func _on_physics_process(_delta: float) -> void:
	print("The wrong is called")
	return


## Call this function to make the enemy loose health and apply a knockback
func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	_health -= damage
	
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
