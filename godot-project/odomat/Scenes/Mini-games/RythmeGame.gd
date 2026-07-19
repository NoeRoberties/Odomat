extends Node2D

@export var arrow_scene: PackedScene

@onready var spawn_left: Marker2D = $SpawnLeft
@onready var spawn_right: Marker2D = $SpawnRight
@onready var spawn_top: Marker2D = $SpawnTop
@onready var spawn_bottom: Marker2D = $SpawnBottom
@onready var target_circle: Area2D = $TargetCircle
@onready var score_label: Label = $ScoreLabel

var success_sound: AudioStreamPlayer
var fail_sound: AudioStreamPlayer
var background: Sprite2D
const SUCCESS_STREAM := preload("res://Assets/Mini-games/RythmeGame/success.ogg")
const FAIL_STREAM := preload("res://Assets/Mini-games/RythmeGame/fail.ogg")
const BG_TEXTURE := preload("res://Assets/Mini-games/RythmeGame/cave_wall_bg.svg")

var arrows_in_zone: Dictionary = {"left": [], "right": [], "up": [], "down": []}
var score: int = 0

var spawn_delay: float = 1.8
var min_spawn_delay: float = 0.7
var delay_step: float = 0.03

var circle_ratio: float = 0.10
var arrow_ratio: float = 0.08
var speed_ratio: float = 0.22

var circle_radius: float = 0.0
var arrow_size: float = 0.0
var arrow_speed: float = 0.0

func _ready() -> void:
	background = Sprite2D.new()
	background.texture = BG_TEXTURE
	background.centered = true
	add_child(background)
	move_child(background, 0)
	success_sound = AudioStreamPlayer.new()
	success_sound.stream = SUCCESS_STREAM
	add_child(success_sound)
	fail_sound = AudioStreamPlayer.new()
	fail_sound.stream = FAIL_STREAM
	add_child(fail_sound)
	_layout()
	get_viewport().size_changed.connect(_layout)
	target_circle.area_entered.connect(_on_target_area_entered)
	target_circle.area_exited.connect(_on_target_area_exited)
	_update_score(0)
	_spawn_next()

func _layout() -> void:
	var vp = get_viewport_rect().size
	var center = vp * 0.5
	var reference = min(vp.x, vp.y)

	circle_radius = reference * circle_ratio
	arrow_size = reference * arrow_ratio
	arrow_speed = vp.y * speed_ratio

	target_circle.position = center
	target_circle.set_radius(circle_radius)

	if background != null and background.texture != null:
		background.position = center
		var tex = background.texture.get_size()
		var s = max(vp.x / tex.x, vp.y / tex.y)
		background.scale = Vector2(s, s)

	var margin = arrow_size
	spawn_left.position = Vector2(-margin, center.y)
	spawn_right.position = Vector2(vp.x + margin, center.y)
	spawn_top.position = Vector2(center.x, -margin)
	spawn_bottom.position = Vector2(center.x, vp.y + margin)

func _update_score(delta: int) -> void:
	score = max(0, score + delta)
	score_label.text = "Score : " + str(score)

func _spawn_next() -> void:
	if arrow_scene == null:
		return

	var arrow = arrow_scene.instantiate() as Area2D
	arrow.speed = arrow_speed
	arrow.hit_size = arrow_size
	var types = ["left", "right", "up", "down"]
	var arrow_type = types[randi() % types.size()]
	arrow.arrow_type = arrow_type

	if arrow_type == "left":
		arrow.position = spawn_right.position
		arrow.set_direction(Vector2.LEFT)
	elif arrow_type == "right":
		arrow.position = spawn_left.position
		arrow.set_direction(Vector2.RIGHT)
	elif arrow_type == "up":
		arrow.position = spawn_bottom.position
		arrow.set_direction(Vector2.UP)
	elif arrow_type == "down":
		arrow.position = spawn_top.position
		arrow.set_direction(Vector2.DOWN)

	add_child(arrow)

	spawn_delay = max(min_spawn_delay, spawn_delay - delay_step)
	get_tree().create_timer(spawn_delay).timeout.connect(_spawn_next)

func _on_target_area_entered(area: Area2D) -> void:
	if "arrow_type" in area:
		arrows_in_zone[area.arrow_type].append(area)

func _on_target_area_exited(area: Area2D) -> void:
	if "arrow_type" in area:
		if area in arrows_in_zone[area.arrow_type]:
			arrows_in_zone[area.arrow_type].erase(area)
			area.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_check_hit("left")
	elif event.is_action_pressed("ui_right"):
		_check_hit("right")
	elif event.is_action_pressed("ui_up"):
		_check_hit("up")
	elif event.is_action_pressed("ui_down"):
		_check_hit("down")

func _check_hit(type: String) -> void:
	print("Touche pressee : ", type)
	if arrows_in_zone[type].size() > 0:
		var hit_arrow = arrows_in_zone[type][0]
		arrows_in_zone[type].pop_front()
		hit_arrow.queue_free()
		_update_score(1)
		success_sound.play()
	else:
		fail_sound.play()
		_remove_closest_arrow()

func _remove_closest_arrow() -> void:
	var center = target_circle.position
	var closest: Arrow = null
	var closest_dist := INF
	for child in get_children():
		if child is Arrow:
			var d = child.position.distance_to(center)
			if d < closest_dist:
				closest_dist = d
				closest = child
	if closest != null:
		if closest in arrows_in_zone[closest.arrow_type]:
			arrows_in_zone[closest.arrow_type].erase(closest)
		closest.queue_free()
