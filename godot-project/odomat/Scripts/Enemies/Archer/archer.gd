extends CharacterBody2D

@export var arrow_scene : PackedScene = preload("res://Scenes/Enemies/Archer/arrow.tscn")

var speed = 90
var flee_speed = 130
var stop_distance = 250.0

var player = null
var in_attack_zone = false
var in_danger_zone = false

var shoot_cooldown = 2.0
var shoot_timer = 0.0


func _physics_process(delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		move_and_slide()
		return

	if in_danger_zone:
		var flee_dir = (global_position - player.global_position).normalized()
		velocity = flee_dir * flee_speed
		$AnimatedSprite2D.play("walk")

	elif in_attack_zone:
		var dist = global_position.distance_to(player.global_position)
		if dist > stop_distance:
			var approach_dir = (player.global_position - global_position).normalized()
			velocity = approach_dir * speed
			$AnimatedSprite2D.play("walk")
		else:
			velocity = Vector2.ZERO
			if $AnimatedSprite2D.animation != "shoot":
				$AnimatedSprite2D.play("idle")
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				shoot()
				shoot_timer = shoot_cooldown

	if in_danger_zone:
		$AnimatedSprite2D.flip_h = (player.position.x > position.x)
	else:
		$AnimatedSprite2D.flip_h = (player.position.x < position.x)

	move_and_slide()

func shoot() -> void:
	if not arrow_scene or not player:
		return
	$AnimatedSprite2D.play("shoot")

	var offset = Vector2(5, -30)
	if $AnimatedSprite2D.flip_h:
		offset.x = -offset.x

	var shoot_pos = global_position + offset

	var arrow = arrow_scene.instantiate()
	arrow.pos = shoot_pos
	arrow.dir = (player.global_position - shoot_pos).angle()
	arrow.rota = arrow.dir
	arrow.target = player
	get_tree().current_scene.add_child(arrow)

func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "shoot":
		$AnimatedSprite2D.play("idle")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player = body
	in_attack_zone = true
	shoot_timer = shoot_cooldown

func _on_attack_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	in_attack_zone = false
	if not in_danger_zone:
		player = null

func _on_danger_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player = body
	in_danger_zone = true

func _on_danger_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	in_danger_zone = false
	if not in_attack_zone:
		player = null
