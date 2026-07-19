extends Node2D

@export var arrow_scene: PackedScene 

@onready var spawn_left: Marker2D = $SpawnLeft
@onready var spawn_right: Marker2D = $SpawnRight
@onready var spawn_top: Marker2D = $SpawnTop
@onready var spawn_bottom: Marker2D = $SpawnBottom

@onready var target_circle: Area2D = $TargetCircle

var arrows_in_zone: Dictionary = {"left": [], "right": [], "up": [], "down": []}

func _ready() -> void:
	target_circle.area_entered.connect(_on_target_area_entered)
	target_circle.area_exited.connect(_on_target_area_exited)
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	if arrow_scene == null:
		print("Attention: Aucune scène Arrow n'est assignée dans l'inspecteur de RythmeGame !")
		return
		
	var arrow = arrow_scene.instantiate() as Area2D 
	
	var types = ["left", "right", "up", "down"]
	var random_type = types[randi() % types.size()]
	
	arrow.arrow_type = random_type
	
	if random_type == "left":
		arrow.position = spawn_left.position
		arrow.set_direction(Vector2.RIGHT)
	elif random_type == "right":
		arrow.position = spawn_right.position
		arrow.set_direction(Vector2.LEFT)
	elif random_type == "up":
		arrow.position = spawn_top.position
		arrow.set_direction(Vector2.DOWN)
	elif random_type == "down":
		arrow.position = spawn_bottom.position
		arrow.set_direction(Vector2.UP)
		
	add_child(arrow)

func _on_target_area_entered(area: Area2D) -> void:
	if "arrow_type" in area:
		arrows_in_zone[area.arrow_type].append(area)

func _on_target_area_exited(area: Area2D) -> void:
	if "arrow_type" in area:
		if area in arrows_in_zone[area.arrow_type]:
			arrows_in_zone[area.arrow_type].erase(area)
			print("Raté ! Direction manquée : ", area.arrow_type)
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
	if arrows_in_zone[type].size() > 0:
		var hit_arrow = arrows_in_zone[type][0]
		arrows_in_zone[type].pop_front()
		hit_arrow.queue_free()
		print("Super ! Touche validée : ", type)
	else:
		print("Appui dans le vide (Mauvais timing) ! Touche : ", type)
