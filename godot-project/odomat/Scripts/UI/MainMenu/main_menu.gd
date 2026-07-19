extends CanvasLayer

const GAMEPLAY_SCENE_PATH := "res://Scenes/Maps/World.tscn"
const SUPPORTED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

@onready var _texture_rect: TextureRect = $TextureRect
@onready var _start_button: Button = %StartGameButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _back_button: Button = %BackButton
@onready var _resolution_selector: OptionButton = %ResolutionSelector
@onready var _apply_button: Button = %ApplyResolutionButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value_label: Label = %VolumeValueLabel
@onready var _main_vbox: VBoxContainer = %MainVBoxContainer
@onready var _settings_vbox: VBoxContainer = %SettingVBoxContainer
@onready var _resolution_label: Label = %ResolutionLabel
@onready var _volume_label: Label = %VolumeLabel
@onready var _resolution_row: HBoxContainer = %ResolutionRow
@onready var _volume_row: HBoxContainer = %VolumeRow

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
	
	# Disable the default white focus outlines on buttons and inputs
	var empty_stylebox := StyleBoxEmpty.new()
	var focus_nodes: Array[Control] = [
		_start_button, _settings_button, _quit_button, _back_button, _apply_button,
		_resolution_selector, _volume_slider
	]
	for node in focus_nodes:
		node.add_theme_stylebox_override("focus", empty_stylebox)
	
	get_viewport().size_changed.connect(_update_layouts)
	_update_layouts()
	
	_main_vbox.show()
	_settings_vbox.hide()
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
	_update_layouts()


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


func _on_settings_button_pressed() -> void:
	_main_vbox.hide()
	_settings_vbox.show()
	_back_button.grab_focus()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	_settings_vbox.hide()
	_main_vbox.show()
	_settings_button.grab_focus()


func _update_layouts() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	
	# 1. Adapt background texture to cover the full viewport keeping aspect ratio
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.position = Vector2.ZERO
	_texture_rect.scale = Vector2.ONE
	_texture_rect.size = viewport_size
	
	# 2. Position and size main containers based on the new viewport size
	# Width: 35% of the viewport width, clamped to a reasonable range [400, 600]
	var container_width := clampf(viewport_size.x * 0.35, 400.0, 600.0)
	var container_height := viewport_size.y * 0.8
	
	# Place the containers on the right with a margin of 50 pixels
	var container_x := viewport_size.x - container_width - 50.0
	var container_y := (viewport_size.y - container_height) / 2.0
	
	_main_vbox.position = Vector2(container_x, container_y)
	_main_vbox.size = Vector2(container_width, container_height)
	
	_settings_vbox.position = Vector2(container_x, container_y)
	_settings_vbox.size = Vector2(container_width, container_height)
	
	# 3. Scale UI elements to fit the viewport height
	var button_height := clampf(viewport_size.y * 0.08, 45.0, 75.0)
	var neon_button_width := button_height * 2.882
	var input_height := clampf(viewport_size.y * 0.06, 35.0, 55.0)
	var font_size := clampi(int(viewport_size.y * 0.022), 14, 22)
	var container_separation := clampi(int(viewport_size.y * 0.02), 12, 24)
	var row_separation := clampi(int(viewport_size.y * 0.015), 8, 16)
	
	# Override button sizes and horizontal alignment to match visible textures exactly
	_start_button.custom_minimum_size = Vector2(neon_button_width, button_height)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	_settings_button.custom_minimum_size = Vector2(neon_button_width, button_height)
	_settings_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	_quit_button.custom_minimum_size = Vector2(neon_button_width, button_height)
	_quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	_back_button.custom_minimum_size = Vector2(neon_button_width, button_height)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	_apply_button.custom_minimum_size = Vector2(0, button_height)
	_apply_button.size_flags_horizontal = Control.SIZE_FILL
	
	# Override input selector and slider sizes
	_resolution_selector.custom_minimum_size = Vector2(0, input_height)
	_volume_slider.custom_minimum_size = Vector2(0, input_height)
	
	# Override font sizes
	var controls_to_scale: Array[Control] = [
		_start_button, _settings_button, _quit_button, _back_button, _apply_button,
		_resolution_label, _volume_label, _volume_value_label, _resolution_selector
	]
	for control in controls_to_scale:
		control.add_theme_font_size_override("font_size", font_size)
	
	# Override separations
	_main_vbox.add_theme_constant_override("separation", container_separation)
	_settings_vbox.add_theme_constant_override("separation", container_separation)
	_resolution_row.add_theme_constant_override("separation", row_separation)
	_volume_row.add_theme_constant_override("separation", row_separation)
