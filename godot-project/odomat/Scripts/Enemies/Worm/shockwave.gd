extends Area2D

@export var grow_time: float = 1.2
@export var stay_time: float = 0.2
@export var fade_time: float = 0.6
@export var damage: int = 15
@export var knockback_force: float = 600.0

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Start at zero scale/radius
	scale = Vector2.ZERO
	modulate.a = 1.0

	body_entered.connect(_on_body_entered)

	_play_animation()

func _play_animation() -> void:
	var tween := create_tween()

	visual.play("default")
	# Grow phase
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), grow_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Optional pause at max size
	tween.tween_interval(stay_time)

	# Fade out phase (fade visually, but you can disable damage earlier)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)

	tween.finished.connect(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # or check via class/type
		if body.has_method("take_damage"):
			body.take_damage(damage, self.global_position, knockback_force)
