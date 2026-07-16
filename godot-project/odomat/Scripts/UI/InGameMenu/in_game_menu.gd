extends CanvasLayer

const MAIN_MENU_SCENE_PATH := "res://Scenes/UI/MainMenu/MainMenu.tscn"
@onready var _escape_game_button: Button = %EscapeGameButton


func _ready() -> void:
	GameState.current_state = GameState.GameState.MENU
	_escape_game_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape_inventory"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _close_menu() -> void:
	GameState.current_state = GameState.GameState.PLAYING
	queue_free()


func _on_escape_game_button_pressed() -> void:
	GameState.current_state = GameState.GameState.MENU
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
