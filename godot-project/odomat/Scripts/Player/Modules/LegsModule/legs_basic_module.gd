class_name LegsBasicModule
extends PlayerModule

@onready var dash_timer: Timer = $DashTimer
@onready var dash_again_timer: Timer = $DashAgainTimer
@onready var dash_bar_1: TextureProgressBar = $DashUI/DashBar1
@onready var dash_bar_2: TextureProgressBar = $DashUI/DashBar2

const BASE_SPEED: float = 150.0
const DASH_SPEED: float = 300.0
const MAX_DASH: int = 2
const ISO_DIRS: Dictionary = {
	"move_up": Vector2(0.0, -1.0),
	"move_right": Vector2(1.0, 0.0),
	"move_down": Vector2(0.0, 1.0),
	"move_left": Vector2(-1.0, 0.0),
}

var _dashing: bool = false
var _dash_count: int = 0

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

	if Input.is_action_just_pressed("dash") and _dash_count < MAX_DASH and move_dir != Vector2.ZERO:
		_dash_count += 1
		_dashing = true
		dash_timer.start()
		if dash_again_timer.is_stopped():
			dash_again_timer.start()

	var current_speed = DASH_SPEED if _dashing else BASE_SPEED
	player.velocity = move_dir.normalized() * current_speed if move_dir != Vector2.ZERO else Vector2.ZERO
	player.move_and_slide()


func _process(_delta: float) -> void:
	if GameState.current_state != GameState.GameState.PLAYING:
		return
	_update_dash_ui()


func _update_dash_ui() -> void:
	var progress := 0.0
	if not dash_again_timer.is_stopped():
		progress = 1.0 - (dash_again_timer.time_left / dash_again_timer.wait_time)

	if _dash_count == 0:
		dash_bar_1.value = 1.0
		dash_bar_2.value = 1.0
	elif _dash_count == 1:
		dash_bar_1.value = 1.0
		dash_bar_2.value = progress
	elif _dash_count == 2:
		dash_bar_1.value = progress
		dash_bar_2.value = 0.0


func _on_dash_timer_timeout() -> void:
	_dashing = false


func _on_dash_again_timer_timeout() -> void:
	if _dash_count > 0:
		_dash_count -= 1
		if _dash_count > 0:
			dash_again_timer.start()
	
