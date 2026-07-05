extends CanvasLayer

const GAMEPLAY_SCENE_PATH := "res://Scenes/Maps/World.tscn"
const SUPPORTED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var _start_button: Button = %StartGameButton
@onready var _resolution_selector: OptionButton = %ResolutionSelector
@onready var _apply_button: Button = %ApplyResolutionButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel

var _pending_resolution: Vector2i
var _master_bus_index: int = 0


func _ready() -> void:
	GameState.current_state = GameState.GameState.MENU
	_master_bus_index = AudioServer.get_bus_index("Master")
	_populate_resolutions()
	_select_current_resolution()
	_pending_resolution = SUPPORTED_RESOLUTIONS[_resolution_selector.selected]
	_update_apply_button_state()
	_sync_volume_ui()
	_start_button.grab_focus()


func _populate_resolutions() -> void:
	_resolution_selector.clear()
	for resolution: Vector2i in SUPPORTED_RESOLUTIONS:
		_resolution_selector.add_item("%dx%d" % [resolution.x, resolution.y])


func _select_current_resolution() -> void:
	var current_size: Vector2i = get_window().size
	for i in SUPPORTED_RESOLUTIONS.size():
		if SUPPORTED_RESOLUTIONS[i] == current_size:
			_resolution_selector.select(i)
			return
	_resolution_selector.select(0)


func _update_apply_button_state() -> void:
	_apply_button.disabled = (_pending_resolution == get_window().size)


func _sync_volume_ui() -> void:
	var current_volume_db := AudioServer.get_bus_volume_db(_master_bus_index)
	var current_volume_percent := clampi(int(round(remap(current_volume_db, -80.0, 0.0, 0.0, 100.0))), 0, 100)
	_volume_slider.value = current_volume_percent
	_volume_value_label.text = "%d%%" % current_volume_percent


func _apply_resolution(resolution: Vector2i) -> void:
	var window_id := DisplayServer.MAIN_WINDOW_ID
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, window_id)
	DisplayServer.window_set_size(resolution, window_id)

	var window := get_window()
	window.size = resolution

	var screen := DisplayServer.window_get_current_screen(window_id)
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	window.position = usable_rect.position + (usable_rect.size - resolution) / 2

	ProjectSettings.set_setting("display/window/size/viewport_width", resolution.x)
	ProjectSettings.set_setting("display/window/size/viewport_height", resolution.y)


func _on_start_game_button_pressed() -> void:
	GameState.current_state = GameState.GameState.PLAYING
	get_tree().change_scene_to_file(GAMEPLAY_SCENE_PATH)


func _on_resolution_selector_item_selected(index: int) -> void:
	if index < 0 or index >= SUPPORTED_RESOLUTIONS.size():
		return
	_pending_resolution = SUPPORTED_RESOLUTIONS[index]
	_update_apply_button_state()


func _on_apply_resolution_button_pressed() -> void:
	_apply_resolution(_pending_resolution)
	_update_apply_button_state()


func _on_volume_slider_value_changed(value: float) -> void:
	var clamped_value := clampf(value, 0.0, 100.0)
	var volume_db := remap(clamped_value, 0.0, 100.0, -80.0, 0.0)
	AudioServer.set_bus_volume_db(_master_bus_index, volume_db)
	_volume_value_label.text = "%d%%" % int(round(clamped_value))