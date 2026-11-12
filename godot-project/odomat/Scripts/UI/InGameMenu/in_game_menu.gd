extends CanvasLayer

const MAIN_MENU_SCENE_PATH := "res://Scenes/UI/MainMenu/MainMenu.tscn"
@onready var _escape_game_button: TextureButton = %EscapeGameButton
var _hover_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_escape_game_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_escape_game_button.pivot_offset = _escape_game_button.size * 0.5
	_escape_game_button.mouse_entered.connect(_on_escape_game_button_mouse_entered)
	_escape_game_button.mouse_exited.connect(_on_escape_game_button_mouse_exited)
	_escape_game_button.grab_focus()


func _on_escape_game_button_mouse_entered() -> void:
	_tween_escape_game_button(1.04)


func _on_escape_game_button_mouse_exited() -> void:
	_tween_escape_game_button(1.0)


func _tween_escape_game_button(target_scale: float) -> void:
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_SINE)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_escape_game_button, "scale", Vector2.ONE * target_scale, 0.12)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape_inventory"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _close_menu() -> void:
	get_tree().paused = false
	queue_free()


func _on_escape_game_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
