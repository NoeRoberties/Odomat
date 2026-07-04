extends CanvasLayer

@onready var _first_button: Button = %ButtonOne


func _ready() -> void:
	GameState.current_state = GameState.GameState.MENU
	_first_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape_inventory"):
		_close_menu()
		get_viewport().set_input_as_handled()


func _close_menu() -> void:
	GameState.current_state = GameState.GameState.PLAYING
	queue_free()


func _on_button_one_pressed() -> void:
	pass


func _on_button_two_pressed() -> void:
	pass
