extends Enemy
class_name Slime

var animated_sprite: AnimatedSprite2D
var wandering_destination: Vector2
var attacking_destination: Vector2

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	choose_wandering_destination()


func load_attack() -> void:
	velocity = Vector2.ZERO
	state = LOADING
	$AttackLoadingTimer.start()


func attack() -> void:
	var direction: Vector2 = attacking_destination - global_position
	
	if direction.length() > 3.0:
		velocity = direction.normalized() * speed * 2
	else:
		load_attack()
	move_and_slide()


func wander() -> void:
	var direction: Vector2 = wandering_destination - global_position
	
	if direction.length() > 5.0:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		choose_wandering_destination()
	move_and_slide()


func choose_wandering_destination() -> void:
	var distance: float = 50.0
	var angle: float = randf() * TAU
	var offset_vector: Vector2 = Vector2(cos(angle), sin(angle)) * distance
	
	wandering_destination = global_position + offset_vector


# To replace later with the player body
func _on_detection_area_mouse_entered() -> void:
	load_attack()


# To replace later with the player body
func _on_detection_area_mouse_exited() -> void:
	state = WANDERING
	$AttackLoadingTimer.stop()
	choose_wandering_destination()


func _on_attack_loading_timer_timeout() -> void:
	state = ATTACKING
	attacking_destination = get_global_mouse_position()
	$AttackLoadingTimer.stop()
