extends CharacterBody2D

@export var arrow_scene : PackedScene = preload("res://Scenes/Enemies/Archer/Arrow.tscn")

var _speed = 90
var _flee_speed = 130
var _shoot_distance = 250.0

var _player = null
var _in_attack_zone = false
var _in_danger_zone = false

var _shoot_cooldown = 1.0
var _shoot_timer = 0.0
var _is_shooting = false


func _physics_process(delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	if _is_shooting:
		move_and_slide()
		return
		
	if _player == null:
		_idle()
		move_and_slide()
		return

	if _in_danger_zone:
		_flee()
	elif _in_attack_zone:
		_attack(delta)

	_update_sprite_direction()
	move_and_slide()


func _idle() -> void:
	velocity = Vector2.ZERO
	$AnimatedSprite2D.play("idle")


func _flee() -> void:
	var flee_dir = (global_position - _player.global_position).normalized()
	velocity = flee_dir * _flee_speed
	$AnimatedSprite2D.play("walk")


func _attack(delta: float) -> void:
	var dist = global_position.distance_to(_player.global_position)
	if dist > _shoot_distance:
		_approach()
	else:
		_try_shoot(delta)


func _approach() -> void:
	var approach_dir = (_player.global_position - global_position).normalized()
	velocity = approach_dir * _speed
	$AnimatedSprite2D.play("walk")


func _try_shoot(delta: float) -> void:
	velocity = Vector2.ZERO
	if not _is_shooting:
		$AnimatedSprite2D.play("idle")
	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot()
		_shoot_timer = _shoot_cooldown


func _update_sprite_direction() -> void:
	if _in_danger_zone:
		$AnimatedSprite2D.flip_h = (_player.position.x > position.x)
	else:
		$AnimatedSprite2D.flip_h = (_player.position.x < position.x)


func _shoot() -> void:
	if not arrow_scene or not _player:
		return

	_is_shooting = true
	var target_position = _player.global_position
	$AnimatedSprite2D.play("shoot")

	var shoot_duration = $AnimatedSprite2D.sprite_frames.get_frame_count("shoot") / $AnimatedSprite2D.sprite_frames.get_animation_speed("shoot")
	await get_tree().create_timer(shoot_duration - 0.5).timeout

	var offset = Vector2(5, -30)
	if $AnimatedSprite2D.flip_h:
		offset.x = -offset.x

	var shoot_pos = global_position + offset

	var arrow = arrow_scene.instantiate()
	arrow.pos = shoot_pos
	arrow.dir = (target_position - shoot_pos).angle()
	arrow.rota = arrow.dir
	arrow.target = _player
	get_tree().current_scene.add_child(arrow)
	
	_is_shooting = false
	$AnimatedSprite2D.play("idle")


func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "shoot":
		_is_shooting = false
		$AnimatedSprite2D.play("idle")


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_in_attack_zone = true
	_shoot_timer = _shoot_cooldown


func _on_attack_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_attack_zone = false
	_is_shooting = false
	_shoot_timer = _shoot_cooldown
	if not _in_danger_zone:
		_player = null


func _on_danger_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_in_danger_zone = true


func _on_danger_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_danger_zone = false
	if not _in_attack_zone:
		_player = null
