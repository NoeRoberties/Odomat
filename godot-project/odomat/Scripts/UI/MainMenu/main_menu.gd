extends CanvasLayer

const GAMEPLAY_SCENE_PATH := "res://Scenes/Maps/World.tscn"
const SUPPORTED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const BG_FRAME_COUNT: int = 57
const BG_FRAME_RATE: float = 10.0 # 10 frames per second
const BG_FRAME_PATH_TEMPLATE: String = "res://Assets/HUD_UI/Main_Menu_Anim/bg_main_menu_%04d.png"

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
var _bg_frames: Array[Texture2D] = []
var _bg_anim_timer: float = 0.0
var _bg_frame_index: int = 0


const BASE_VIEWPORT_SIZE := Vector2(1600.0, 900.0)

var _base_captured: bool = false
var _base_main_vbox_rect: Rect2
var _base_settings_vbox_rect: Rect2
var _base_right_margin_main: float
var _base_right_margin_settings: float
var _base_min_sizes: Dictionary = {}
var _base_font_sizes: Dictionary = {}
var _base_separations: Dictionary = {}


func _ready() -> void:
	_init_background_animation()
	_capture_base_editor_settings()
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


func _process(delta: float) -> void:
	_update_background_animation(delta)


func _init_background_animation() -> void:
	_bg_frames.clear()
	for i in range(1, BG_FRAME_COUNT + 1):
		var frame_path := BG_FRAME_PATH_TEMPLATE % i
		var tex := load(frame_path) as Texture2D
		if tex != null:
			_bg_frames.append(tex)
	if not _bg_frames.is_empty():
		_texture_rect.texture = _bg_frames[0]


func _update_background_animation(delta: float) -> void:
	if _bg_frames.is_empty():
		return
	
	_bg_anim_timer += delta
	var frame_duration := 1.0 / BG_FRAME_RATE
	if _bg_anim_timer >= frame_duration:
		var advance := int(_bg_anim_timer / frame_duration)
		_bg_anim_timer = fmod(_bg_anim_timer, frame_duration)
		_bg_frame_index = (_bg_frame_index + advance) % _bg_frames.size()
		_texture_rect.texture = _bg_frames[_bg_frame_index]



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


func _capture_base_editor_settings() -> void:
	if _base_captured:
		return
	_base_captured = true
	
	_base_main_vbox_rect = Rect2(_main_vbox.position, _main_vbox.size)
	_base_settings_vbox_rect = Rect2(_settings_vbox.position, _settings_vbox.size)
	
	_base_right_margin_main = BASE_VIEWPORT_SIZE.x - (_main_vbox.position.x + _main_vbox.size.x)
	_base_right_margin_settings = BASE_VIEWPORT_SIZE.x - (_settings_vbox.position.x + _settings_vbox.size.x)
	
	var controls_to_track: Array[Control] = [
		_start_button, _settings_button, _quit_button, _back_button, _apply_button,
		_resolution_selector, _volume_slider, _resolution_label, _volume_label, _volume_value_label
	]
	for ctrl: Control in controls_to_track:
		if ctrl != null:
			if ctrl.custom_minimum_size != Vector2.ZERO:
				_base_min_sizes[ctrl] = ctrl.custom_minimum_size
			var fs: int = ctrl.get_theme_font_size("font_size")
			if fs > 0:
				_base_font_sizes[ctrl] = fs
	
	var containers: Array[BoxContainer] = [
		_main_vbox, _settings_vbox, _resolution_row, _volume_row
	]
	for c: BoxContainer in containers:
		if c != null:
			_base_separations[c] = c.get_theme_constant("separation")


func _update_layouts() -> void:
	_capture_base_editor_settings()
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := viewport_size.y / BASE_VIEWPORT_SIZE.y
	
	# Background covers full viewport
	_texture_rect.size = viewport_size
	
	# If running at the design resolution (1600x900), preserve exact editor values
	if is_equal_approx(scale_factor, 1.0):
		_main_vbox.position = _base_main_vbox_rect.position
		_main_vbox.size = _base_main_vbox_rect.size
		_settings_vbox.position = _base_settings_vbox_rect.position
		_settings_vbox.size = _base_settings_vbox_rect.size
		
		for ctrl: Control in _base_min_sizes:
			ctrl.custom_minimum_size = _base_min_sizes[ctrl]
		for ctrl: Control in _base_font_sizes:
			ctrl.add_theme_font_size_override("font_size", _base_font_sizes[ctrl])
		for c: BoxContainer in _base_separations:
			c.add_theme_constant_override("separation", _base_separations[c])
		return
	
	# When resolution changes, scale proportionally based on the editor design
	var new_main_w := _base_main_vbox_rect.size.x * scale_factor
	var new_main_h := _base_main_vbox_rect.size.y * scale_factor
	var new_main_right := _base_right_margin_main * scale_factor
	_main_vbox.size = Vector2(new_main_w, new_main_h)
	_main_vbox.position = Vector2(
		viewport_size.x - new_main_w - new_main_right,
		(viewport_size.y - new_main_h) / 2.0
	)
	
	var new_set_w := _base_settings_vbox_rect.size.x * scale_factor
	var new_set_h := _base_settings_vbox_rect.size.y * scale_factor
	var new_set_right := _base_right_margin_settings * scale_factor
	_settings_vbox.size = Vector2(new_set_w, new_set_h)
	_settings_vbox.position = Vector2(
		viewport_size.x - new_set_w - new_set_right,
		(viewport_size.y - new_set_h) / 2.0
	)
	
	for ctrl: Control in _base_min_sizes:
		ctrl.custom_minimum_size = _base_min_sizes[ctrl] * scale_factor
	
	for ctrl: Control in _base_font_sizes:
		var scaled_font := int(round(_base_font_sizes[ctrl] * scale_factor))
		ctrl.add_theme_font_size_override("font_size", max(10, scaled_font))
	
	for c: BoxContainer in _base_separations:
		var scaled_sep := int(round(_base_separations[c] * scale_factor))
		c.add_theme_constant_override("separation", max(2, scaled_sep))
