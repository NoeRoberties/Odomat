extends Enemy
class_name Slime

var animated_sprite: AnimatedSprite2D
var wandering_destination: Vector2
var state = WANDERING

func _ready() -> void:
	speed = 35
	animated_sprite = $AnimatedSprite2D
	choose_wandering_destination()


func _process(delta: float) -> void:
	if state == WANDERING:
		wander(delta)
	if state == ATTACKING:
		attack_player(delta)


func attack_player(delta: float) -> void:
	print("Attack.")


func wander(delta: float) -> void:
	var direction: Vector2 = wandering_destination - global_position
	
	print(direction.length())
	if direction.length() > 5:
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
