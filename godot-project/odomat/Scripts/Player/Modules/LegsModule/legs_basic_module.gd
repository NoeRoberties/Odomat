class_name LegsBasicModule
extends PlayerModule


const BASE_SPEED: float = 150.0
const ISO_DIRS: Dictionary = {
	"move_up": Vector2(0.0, -1.0),
	"move_right": Vector2(1.0, 0.0),
	"move_down": Vector2(0.0, 1.0),
	"move_left": Vector2(-1.0, 0.0),
}

#
#func handle_physics(player: CharacterBody2D, _delta: float) -> void:
	#if GameState.current_state != GameState.GameState.PLAYING:
		#return
#
	#var move_dir := Vector2.ZERO
	#for action: String in ISO_DIRS:
		#if Input.is_action_pressed(action):
			#move_dir += ISO_DIRS[action]
#
	#player.velocity = move_dir.normalized() * BASE_SPEED if move_dir != Vector2.ZERO else Vector2.ZERO
	#player.move_and_slide()


func _physics_process(_delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return

	var player = get_parent()
	if player == null:
		return

	var move_dir := Vector2.ZERO
	for action: String in ISO_DIRS:
		if Input.is_action_pressed(action):
			move_dir += ISO_DIRS[action]

	player.velocity = move_dir.normalized() * BASE_SPEED if move_dir != Vector2.ZERO else Vector2.ZERO
	player.move_and_slide()
	
